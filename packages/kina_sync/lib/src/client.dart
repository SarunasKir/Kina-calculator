import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;
import 'package:kina_data/kina_data.dart';
import 'package:kina_sync/src/changes.dart';
import 'package:kina_sync/src/cipher.dart';
import 'package:kina_sync/src/discovery.dart';
import 'package:kina_sync/src/hub.dart' show clockMismatch;
import 'package:kina_sync/src/pairing.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

const _deviceIdKey = 'sync.deviceId';
const _pairingKey = 'sync.pairing';
const _cursorKey = 'sync.cursor';

/// Thrown when pairing or syncing fails. The message is for the user.
class SyncException implements Exception {
  /// Creates the exception.
  const SyncException(this.message);

  /// What went wrong, in words.
  final String message;

  @override
  String toString() => message;
}

/// The hub a phone is paired with.
@immutable
class HubPairing {
  /// Creates a pairing.
  const HubPairing({
    required this.hubId,
    required this.addresses,
    required this.port,
    required this.key,
  });

  /// Reads a pairing from JSON.
  factory HubPairing.fromJson(Map<String, Object?> json) => HubPairing(
    hubId: json['hubId']! as String,
    addresses: [
      for (final a in json['addresses']! as List<Object?>) a! as String,
    ],
    port: json['port']! as int,
    key: json['key']! as String,
  );

  /// The hub's id.
  final String hubId;

  /// Where the hub was last reachable.
  final List<String> addresses;

  /// The hub's port.
  final int port;

  /// The key shared with the hub, base64.
  final String key;

  /// Returns a copy reachable at [address] and [port].
  HubPairing movedTo(String address, int port) => HubPairing(
    hubId: hubId,
    addresses: [address, ...addresses.where((a) => a != address)],
    port: port,
    key: key,
  );

  /// Converts to JSON.
  Map<String, Object?> toJson() => {
    'hubId': hubId,
    'addresses': addresses,
    'port': port,
    'key': key,
  };
}

/// What one sync did.
@immutable
class SyncReport {
  /// Creates a report.
  const SyncReport({
    required this.sent,
    required this.received,
    required this.applied,
    required this.at,
  });

  /// Records sent to the hub.
  final int sent;

  /// Records the hub sent back.
  final int received;

  /// Of those, records that were newer than ours and were stored.
  final int applied;

  /// When the sync finished.
  final DateTime at;
}

/// The phone side: pairs with a hub and exchanges changes with it.
class SyncClient {
  /// Creates a client for [db] that keeps its pairing in [store].
  SyncClient({
    required KinaDatabase db,
    required LocalStore store,
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
    Future<FoundHub?> Function(String hubId)? discover,
  }) : _db = db,
       _store = store,
       _injected = client,
       _discover = discover ?? discoverHub;

  /// How long to wait for the hub at each address.
  final Duration timeout;

  final KinaDatabase _db;
  final LocalStore _store;
  // A fresh connection per request unless a client is given (tests): a
  // reused connection to a hub that restarted would fail once.
  final http.Client? _injected;
  final Future<FoundHub?> Function(String hubId) _discover;

  Future<String> _deviceId() async {
    final known = await _store.read(_deviceIdKey);
    if (known != null) {
      return known;
    }
    final fresh = const Uuid().v4();
    await _store.write(_deviceIdKey, fresh);
    return fresh;
  }

  /// The hub this device is paired with, or null.
  Future<HubPairing?> pairing() async {
    final text = await _store.read(_pairingKey);
    return text == null
        ? null
        : HubPairing.fromJson(jsonDecode(text) as Map<String, Object?>);
  }

  /// Forgets the hub. Local data stays; syncing stops.
  Future<void> unpair() async {
    await _store.remove(_pairingKey);
    await _store.remove(_cursorKey);
  }

  Future<String> _post(
    HubPairing target,
    String address,
    String path,
    String body, {
    Map<String, String> headers = const {},
  }) async {
    final client = _injected ?? http.Client();
    final http.Response response;
    try {
      response = await client
          .post(
            Uri(scheme: 'http', host: address, port: target.port, path: path),
            headers: headers,
            body: body,
          )
          .timeout(timeout);
    } finally {
      if (_injected == null) {
        client.close();
      }
    }
    if (response.statusCode == HttpStatus.unauthorized) {
      if (response.body == clockMismatch) {
        throw const SyncException(
          'The clocks on this device and the PC differ by too much. '
          'Set both to automatic time.',
        );
      }
      throw SyncException(
        path == '/pair'
            ? 'The hub refused the pairing code. Make a new one on the PC.'
            : 'This device is no longer paired. Pair it again.',
      );
    }
    if (response.statusCode != HttpStatus.ok) {
      throw SyncException('The hub answered ${response.statusCode}');
    }
    return response.body;
  }

  /// Tries each address of [target], then looks for the hub on the network.
  /// Returns the answer and the target that worked.
  Future<(String, HubPairing)> _reach(
    HubPairing target,
    Future<String> Function(HubPairing target, String address) attempt,
  ) async {
    Object? failure;
    for (final address in target.addresses) {
      try {
        return (await attempt(target, address), target);
      } on SyncException {
        rethrow;
      } on Object catch (e) {
        failure = e;
      }
    }
    final found = await _discover(target.hubId);
    if (found != null) {
      final moved = target.movedTo(found.address, found.port);
      try {
        return (await attempt(moved, found.address), moved);
      } on SyncException {
        rethrow;
      } on Object catch (e) {
        failure = e;
      }
    }
    throw SyncException(
      'Could not reach the PC. Is the sync hub running and on the same '
      'Wi-Fi? ($failure)',
    );
  }

  /// Pairs with the hub that made [code].
  ///
  /// Throws [FormatException] for a bad code and [SyncException] if the hub
  /// cannot be reached or refuses.
  Future<void> pair(String code, {required String deviceName}) async {
    final offer = PairingOffer.parse(code);
    final device = await _deviceId();
    final target = HubPairing(
      hubId: offer.hubId,
      addresses: offer.addresses,
      port: offer.port,
      key: '',
    );
    final box = await offer.cipher.seal({
      'ts': clock.now().toUtc().toIso8601String(),
    }, 'pair:$device');
    final (answer, reached) = await _reach(
      target,
      (t, address) => _post(
        t,
        address,
        '/pair',
        jsonEncode({'device': device, 'name': deviceName, 'box': box}),
      ),
    );
    final Map<String, Object?> reply;
    try {
      reply = await offer.cipher.open(answer, 'pair-reply:$device');
    } on CipherException {
      throw const SyncException('The hub answered with something unreadable');
    }
    final paired = HubPairing(
      hubId: reply['hub']! as String,
      addresses: reached.addresses,
      port: reached.port,
      key: reply['key']! as String,
    );
    await _store.write(_pairingKey, jsonEncode(paired.toJson()));
    await _store.remove(_cursorKey);
  }

  /// Sends our changes to the hub and stores the newer ones it has.
  ///
  /// Throws [SyncException] if not paired, or the hub cannot be reached.
  Future<SyncReport> syncNow() async {
    final target = await pairing();
    if (target == null) {
      throw const SyncException('This device is not paired with a PC yet');
    }
    final device = await _deviceId();
    final cipher = SyncCipher.fromBase64(target.key);
    final cursorText = await _store.read(_cursorKey);
    final cursor = cursorText == null
        ? const <String, Object?>{}
        : jsonDecode(cursorText) as Map<String, Object?>;
    final since = cursor['since'] as String?;
    final pushed = cursor['pushed'] as String?;
    final started = _now();
    final outgoing = await exportChanges(
      _db,
      since: pushed == null ? null : DateTime.parse(pushed),
    );
    final box = await cipher.seal({
      'ts': started.toIso8601String(),
      'since': since,
      'changes': outgoing.toJson(),
    }, 'sync:$device');
    final (answer, reached) = await _reach(
      target,
      (t, address) =>
          _post(t, address, '/sync', box, headers: {'x-kina-device': device}),
    );
    final Map<String, Object?> reply;
    try {
      reply = await cipher.open(answer, 'sync-reply:$device');
    } on CipherException {
      throw const SyncException('The hub answered with something unreadable');
    }
    final incoming = ChangeSet.fromJson(
      reply['changes']! as Map<String, Object?>,
    );
    final result = await applyChanges(_db, incoming);
    if (reached != target) {
      await _store.write(_pairingKey, jsonEncode(reached.toJson()));
    }
    await _store.write(
      _cursorKey,
      jsonEncode({'since': reply['now'], 'pushed': started.toIso8601String()}),
    );
    return SyncReport(
      sent: outgoing.length,
      received: incoming.length,
      applied: result.applied,
      at: clock.now(),
    );
  }

  DateTime _now() => clock.now().toUtc();
}
