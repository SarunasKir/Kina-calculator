import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/providers.dart';
import 'package:kina_data/kina_data.dart';
import 'package:kina_sync/kina_sync.dart';

/// Which side of the sync this device plays.
enum SyncRole {
  /// The PC: runs the sync server and pairs phones.
  hub,

  /// A phone: pairs with the PC and syncs with it.
  phone,
}

/// This device's sync role: the Windows PC is the hub, everything else a
/// phone. Tests override it.
final syncRoleProvider = Provider<SyncRole>(
  // coverage:ignore-start
  (ref) => Platform.isWindows ? SyncRole.hub : SyncRole.phone,
  // coverage:ignore-end
);

/// The name this device gives itself when pairing. Tests override it.
final deviceNameProvider = Provider<String>(
  // coverage:ignore-start
  (ref) => Platform.isAndroid ? 'Android phone' : Platform.localHostname,
  // coverage:ignore-end
);

/// Device-only storage (pairing keys, sync switches).
final localStoreProvider = Provider<LocalStore>(
  (ref) => LocalStore(ref.watch(databaseProvider)),
);

/// Refreshes every screen's data after sync or import changed the database.
void refreshData(Ref ref) => ref
  ..invalidate(settingsProvider)
  ..invalidate(profilesProvider)
  ..invalidate(snapshotsProvider)
  ..invalidate(journalProvider);

/// Creates the sync server. Tests override this with one on a free port.
final syncHubProvider = Provider<SyncHub>(
  (ref) => SyncHub(
    db: ref.watch(databaseProvider),
    store: ref.watch(localStoreProvider),
  ),
);

/// Creates the phone-side client. Tests override this.
final syncClientProvider = Provider<SyncClient>(
  (ref) => SyncClient(
    db: ref.watch(databaseProvider),
    store: ref.watch(localStoreProvider),
  ),
);

const _enabledKey = 'sync.hubEnabled';

/// The state of the PC's sync server.
class HubState {
  /// Creates the state.
  const HubState({required this.running, required this.devices});

  /// Whether phones can sync right now.
  final bool running;

  /// The paired phones.
  final List<PairedDevice> devices;
}

/// Runs the sync server on the PC and lists the paired phones. The server
/// starts when the app opens if it was switched on before.
final hubControllerProvider = AsyncNotifierProvider<HubController, HubState>(
  HubController.new,
);

/// Controls the sync server.
class HubController extends AsyncNotifier<HubState> {
  StreamSubscription<ApplyResult>? _subscription;
  DiscoveryResponder? _responder;

  @override
  Future<HubState> build() async {
    final hub = ref.watch(syncHubProvider);
    ref.onDispose(() async {
      await _subscription?.cancel();
      _responder?.stop();
      await hub.stop();
    });
    final enabled = await ref.read(localStoreProvider).read(_enabledKey);
    if (enabled == '1') {
      await _start(hub);
    }
    return HubState(running: hub.running, devices: await hub.devices());
  }

  Future<void> _start(SyncHub hub) async {
    await hub.start();
    _subscription ??= hub.changes.listen((_) => refreshData(ref));
    if (_responder == null) {
      final responder = DiscoveryResponder(
        hubId: await hub.hubId(),
        hubPort: hub.boundPort!,
        port: ref.read(discoveryPortProvider),
      );
      try {
        await responder.start();
        _responder = responder;
      } on SocketException {
        // Another copy is already answering; phones can still pair by code.
      }
    }
  }

  /// Switches the server on or off, and remembers the choice.
  Future<void> setRunning({required bool running}) async {
    final hub = ref.read(syncHubProvider);
    await ref.read(localStoreProvider).write(_enabledKey, running ? '1' : '0');
    if (running) {
      await _start(hub);
    } else {
      _responder?.stop();
      _responder = null;
      await hub.stop();
    }
    state = AsyncData(
      HubState(running: hub.running, devices: await hub.devices()),
    );
  }

  /// Makes a pairing code for a new phone.
  Future<PairingOffer> createOffer() => ref.read(syncHubProvider).createOffer();

  /// Reloads the device list.
  Future<void> reload() async {
    final hub = ref.read(syncHubProvider);
    state = AsyncData(
      HubState(running: hub.running, devices: await hub.devices()),
    );
  }

  /// Removes a phone.
  Future<void> remove(PairedDevice device) async {
    await ref.read(syncHubProvider).revoke(device.id);
    await reload();
  }
}

/// The UDP port for discovery. Tests override it with a free port.
final discoveryPortProvider = Provider<int>((ref) => discoveryPort);

/// The phone's pairing with the PC, or null.
final pairingProvider = AsyncNotifierProvider<PairingController, HubPairing?>(
  PairingController.new,
);

/// Pairs the phone with the PC and syncs.
class PairingController extends AsyncNotifier<HubPairing?> {
  @override
  Future<HubPairing?> build() => ref.watch(syncClientProvider).pairing();

  /// Pairs using [code]. Throws [FormatException] or [SyncException].
  Future<void> pair(String code) async {
    final client = ref.read(syncClientProvider);
    await client.pair(code, deviceName: ref.read(deviceNameProvider));
    state = AsyncData(await client.pairing());
  }

  /// Syncs now and refreshes the screens. Throws [SyncException].
  Future<SyncReport> syncNow() async {
    final report = await ref.read(syncClientProvider).syncNow();
    refreshData(ref);
    return report;
  }

  /// Syncs quietly when the app opens: does nothing if not paired or the PC
  /// is not reachable.
  Future<void> autoSync() async {
    if (await future == null) {
      return;
    }
    try {
      await syncNow();
    } on SyncException {
      // The PC is off or elsewhere; the Sync now button explains.
    }
  }

  /// Forgets the PC.
  Future<void> unpair() async {
    await ref.read(syncClientProvider).unpair();
    state = const AsyncData(null);
  }
}
