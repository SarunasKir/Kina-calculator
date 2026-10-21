import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:kina_data/kina_data.dart';
import 'package:kina_sync/src/changes.dart';
import 'package:kina_sync/src/cipher.dart';
import 'package:kina_sync/src/pairing.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// The port the sync server listens on by default.
const hubPort = 47821;

/// How long a pairing code works.
const offerLifetime = Duration(minutes: 10);

/// How far a message's timestamp may differ from the hub's clock.
const maxClockSkew = Duration(minutes: 10);

/// What the hub answers when a message's timestamp is too far from its clock.
const clockMismatch = 'Clock mismatch';

const _hubIdKey = 'sync.hubId';
const _devicesKey = 'sync.devices';

/// A phone that has paired with the hub.
@immutable
class PairedDevice {
  /// Creates a paired device.
  const PairedDevice({
    required this.id,
    required this.name,
    required this.key,
    required this.pairedAt,
    this.lastSyncAt,
  });

  /// Reads a device from JSON.
  factory PairedDevice.fromJson(Map<String, Object?> json) => PairedDevice(
    id: json['id']! as String,
    name: json['name']! as String,
    key: json['key']! as String,
    pairedAt: DateTime.parse(json['pairedAt']! as String),
    lastSyncAt: json['lastSyncAt'] == null
        ? null
        : DateTime.parse(json['lastSyncAt']! as String),
  );

  /// The device's id.
  final String id;

  /// A name to show, such as "Pixel 8".
  final String name;

  /// The device's key, base64.
  final String key;

  /// When it paired.
  final DateTime pairedAt;

  /// When it last synced.
  final DateTime? lastSyncAt;

  /// Returns a copy that last synced at [time].
  PairedDevice syncedAt(DateTime time) => PairedDevice(
    id: id,
    name: name,
    key: key,
    pairedAt: pairedAt,
    lastSyncAt: time,
  );

  /// Converts to JSON.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'key': key,
    'pairedAt': pairedAt.toIso8601String(),
    'lastSyncAt': lastSyncAt?.toIso8601String(),
  };
}

/// The sync server that runs inside the PC app. Phones pair with it once and
/// then exchange changes whenever they are on the same network.
class SyncHub {
  /// Creates a hub that serves [db] and keeps its pairing data in [store].
  SyncHub({
    required KinaDatabase db,
    required LocalStore store,
    this.port = hubPort,
    Future<List<String>> Function()? addresses,
  }) : _db = db,
       _store = store,
       _addresses = addresses ?? localAddresses;

  /// The port to listen on. 0 picks a free one.
  final int port;

  final KinaDatabase _db;
  final LocalStore _store;
  final Future<List<String>> Function() _addresses;
  final _offers = <PairingOffer, DateTime>{};
  final _changed = StreamController<ApplyResult>.broadcast();
  HttpServer? _server;
  String? _hubId;

  /// Emits after a phone's changes were stored.
  Stream<ApplyResult> get changes => _changed.stream;

  /// The port actually listened on, once started.
  int? get boundPort => _server?.port;

  /// Whether the server is running.
  bool get running => _server != null;

  /// This hub's id; created on first use.
  Future<String> hubId() async {
    final known = _hubId ?? await _store.read(_hubIdKey);
    if (known != null) {
      return _hubId = known;
    }
    final fresh = const Uuid().v4();
    await _store.write(_hubIdKey, fresh);
    return _hubId = fresh;
  }

  /// Starts serving. Does nothing if already running.
  Future<void> start() async {
    if (_server != null) {
      return;
    }
    await hubId();
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server = server;
    unawaited(server.forEach(_handle));
  }

  /// Stops serving.
  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  /// Creates a pairing code for a new phone. Run [start] first.
  Future<PairingOffer> createOffer() async {
    final offer = PairingOffer.create(
      hubId: await hubId(),
      addresses: await _addresses(),
      port: boundPort ?? port,
    );
    _offers[offer] = clock.now().add(offerLifetime);
    return offer;
  }

  /// The paired phones.
  Future<List<PairedDevice>> devices() async {
    final text = await _store.read(_devicesKey);
    if (text == null) {
      return [];
    }
    return [
      for (final d in jsonDecode(text) as List<Object?>)
        PairedDevice.fromJson(d! as Map<String, Object?>),
    ];
  }

  Future<void> _saveDevices(List<PairedDevice> devices) => _store.write(
    _devicesKey,
    jsonEncode([for (final d in devices) d.toJson()]),
  );

  /// Removes a phone: it can no longer sync.
  Future<void> revoke(String deviceId) async {
    final all = await devices();
    await _saveDevices([
      for (final d in all)
        if (d.id != deviceId) d,
    ]);
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method != 'POST') {
        await _reply(request, HttpStatus.methodNotAllowed, 'POST only');
        return;
      }
      final body = await utf8.decodeStream(request);
      switch (request.uri.path) {
        case '/pair':
          await _pair(request, body);
        case '/sync':
          await _sync(request, body);
        default:
          await _reply(request, HttpStatus.notFound, 'Not found');
      }
    } on Object {
      await _reply(request, HttpStatus.badRequest, 'Bad request');
    }
  }

  Future<void> _reply(HttpRequest request, int status, String body) async {
    request.response
      ..statusCode = status
      ..write(body);
    await request.response.close();
  }

  bool _fresh(Object? ts) =>
      ts is String &&
      clock.now().difference(DateTime.parse(ts)).abs() <= maxClockSkew;

  Future<void> _pair(HttpRequest request, String body) async {
    final json = jsonDecode(body) as Map<String, Object?>;
    final device = json['device']! as String;
    final name = json['name']! as String;
    final now = clock.now();
    _offers.removeWhere((_, expires) => expires.isBefore(now));
    for (final offer in _offers.keys.toList()) {
      final Map<String, Object?> message;
      try {
        message = await offer.cipher.open(
          json['box']! as String,
          'pair:$device',
        );
      } on CipherException {
        continue;
      }
      if (!_fresh(message['ts'])) {
        break;
      }
      _offers.remove(offer);
      final key = SyncCipher.random();
      final others = [
        for (final d in await devices())
          if (d.id != device) d,
      ];
      await _saveDevices([
        ...others,
        PairedDevice(id: device, name: name, key: key.keyBase64, pairedAt: now),
      ]);
      final reply = await offer.cipher.seal({
        'key': key.keyBase64,
        'hub': await hubId(),
      }, 'pair-reply:$device');
      await _reply(request, HttpStatus.ok, reply);
      return;
    }
    await _reply(request, HttpStatus.unauthorized, 'Pairing refused');
  }

  Future<void> _sync(HttpRequest request, String body) async {
    final deviceId = request.headers.value('x-kina-device');
    final known = (await devices()).where((d) => d.id == deviceId);
    if (deviceId == null || known.isEmpty) {
      await _reply(request, HttpStatus.unauthorized, 'Not paired');
      return;
    }
    final device = known.single;
    final cipher = SyncCipher.fromBase64(device.key);
    final Map<String, Object?> message;
    try {
      message = await cipher.open(body, 'sync:$deviceId');
    } on CipherException {
      await _reply(request, HttpStatus.unauthorized, 'Not paired');
      return;
    }
    if (!_fresh(message['ts'])) {
      await _reply(request, HttpStatus.unauthorized, clockMismatch);
      return;
    }
    final result = await applyChanges(
      _db,
      ChangeSet.fromJson(message['changes']! as Map<String, Object?>),
    );
    final since = message['since'] as String?;
    final outgoing = await exportChanges(
      _db,
      since: since == null ? null : DateTime.parse(since),
    );
    final now = clock.now().toUtc();
    await _saveDevices([
      for (final d in await devices())
        if (d.id == deviceId) d.syncedAt(now) else d,
    ]);
    if (result.applied > 0) {
      _changed.add(result);
    }
    await _reply(
      request,
      HttpStatus.ok,
      await cipher.seal({
        'now': now.toIso8601String(),
        'changes': outgoing.toJson(),
      }, 'sync-reply:$deviceId'),
    );
  }
}

/// This computer's IPv4 addresses on the local network.
Future<List<String>> localAddresses() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );
  return [
    for (final i in interfaces)
      for (final a in i.addresses)
        if (!a.isLoopback && !a.isLinkLocal) a.address,
  ];
}
