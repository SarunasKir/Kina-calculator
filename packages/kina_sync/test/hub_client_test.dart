import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;
import 'package:kina_data/kina_data.dart';
import 'package:kina_sync/kina_sync.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late KinaDatabase pcDb;
  late KinaDatabase phoneDb;
  late SyncHub hub;
  late SyncClient phone;

  Future<List<String>> items(KinaDatabase db) async => [
    for (final e in await JournalRepository(db).list()) e.item,
  ];

  Future<SyncHub> startHub({Clock? atTime, int port = 0}) async {
    final h = SyncHub(
      db: pcDb,
      store: LocalStore(pcDb),
      port: port,
      addresses: () async => ['127.0.0.1'],
    );
    await withClock(atTime ?? clock, h.start);
    return h;
  }

  SyncClient newClient({
    KinaDatabase? db,
    http.Client? client,
    Future<FoundHub?> Function(String)? discover,
  }) => SyncClient(
    db: db ?? phoneDb,
    store: LocalStore(db ?? phoneDb),
    client: client,
    timeout: const Duration(seconds: 2),
    discover: discover ?? (_) async => null,
  );

  setUp(() async {
    pcDb = openTestDatabase();
    phoneDb = openTestDatabase();
    hub = await startHub();
    phone = newClient();
  });
  tearDown(() async {
    await hub.stop();
    await pcDb.close();
    await phoneDb.close();
  });

  Future<void> pairPhone([SyncClient? client]) async {
    final offer = await hub.createOffer();
    await (client ?? phone).pair(offer.code, deviceName: 'Pixel');
  }

  test('pairs, then syncs in both directions', () async {
    expect(await phone.pairing(), isNull);
    await JournalRepository(pcDb).add(entry('pc', 'On the PC'));
    await JournalRepository(phoneDb).add(entry('ph', 'On the phone'));

    await pairPhone();
    final pairing = (await phone.pairing())!;
    expect(pairing.addresses, ['127.0.0.1']);
    expect(pairing.port, hub.boundPort);
    final devices = await hub.devices();
    expect(devices.single.name, 'Pixel');
    expect(devices.single.lastSyncAt, isNull);

    final changed = hub.changes.first;
    final report = await phone.syncNow();
    expect(report.sent, 1);
    expect(report.received, greaterThanOrEqualTo(1));
    expect(report.applied, 1);
    expect((await changed).applied, 1);
    expect(await items(pcDb), unorderedEquals(['On the PC', 'On the phone']));
    expect(
      await items(phoneDb),
      unorderedEquals(['On the PC', 'On the phone']),
    );
    expect((await hub.devices()).single.lastSyncAt, isNotNull);

    // The next sync only moves what changed since.
    await JournalRepository(phoneDb).add(entry('ph2', 'Later'));
    final second = await phone.syncNow();
    expect(second.sent, 1);
    expect(await items(pcDb), contains('Later'));
  });

  test('settings and profiles sync too', () async {
    await ProfileRepository(pcDb).save('Cheap', CalculatorSettings.defaults);
    await SettingsRepository(
      phoneDb,
    ).save(CalculatorSettings.defaults.copyWith(amountMillions: '7'));
    await pairPhone();
    await phone.syncNow();
    expect((await ProfileRepository(phoneDb).list()).single.name, 'Cheap');
    expect((await SettingsRepository(pcDb).load()).amountMillions, '7');
  });

  test('syncing before pairing explains what to do', () async {
    await expectLater(
      phone.syncNow(),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('not paired'),
        ),
      ),
    );
  });

  test('a pairing code works once', () async {
    final offer = await hub.createOffer();
    await phone.pair(offer.code, deviceName: 'Pixel');
    final other = newClient(db: openTestDatabase());
    await expectLater(
      other.pair(offer.code, deviceName: 'Tablet'),
      throwsA(isA<SyncException>()),
    );
    expect(await hub.devices(), hasLength(1));
  });

  test('a pairing code expires', () async {
    var now = DateTime.utc(2026, 10, 21, 12);
    final fake = Clock(() => now);
    await hub.stop();
    hub = await startHub(atTime: fake);
    final offer = await withClock(fake, hub.createOffer);
    now = now.add(offerLifetime + const Duration(seconds: 1));
    await expectLater(
      withClock(fake, () => phone.pair(offer.code, deviceName: 'Pixel')),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('refused'),
        ),
      ),
    );
    expect(await hub.devices(), isEmpty);
  });

  test('a code made by another hub is refused', () async {
    final other = SyncHub(
      db: openTestDatabase(),
      store: LocalStore(pcDb),
      port: 0,
      addresses: () async => ['127.0.0.1'],
    );
    await other.start();
    addTearDown(other.stop);
    final offer = await other.createOffer();
    final forged = PairingOffer(
      hubId: offer.hubId,
      addresses: offer.addresses,
      port: hub.boundPort!,
      secret: offer.secret,
    );
    await expectLater(
      phone.pair(forged.code, deviceName: 'Pixel'),
      throwsA(isA<SyncException>()),
    );
  });

  test('a removed phone can no longer sync', () async {
    await pairPhone();
    await hub.revoke((await hub.devices()).single.id);
    await expectLater(
      phone.syncNow(),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('no longer paired'),
        ),
      ),
    );
  });

  test('a phone that unpairs forgets the hub', () async {
    await pairPhone();
    await phone.unpair();
    expect(await phone.pairing(), isNull);
  });

  test('re-pairing the same phone replaces its entry', () async {
    await pairPhone();
    await pairPhone();
    expect(await hub.devices(), hasLength(1));
    await phone.syncNow();
  });

  test('refuses requests with the wrong key', () async {
    await pairPhone();
    final pairing = (await phone.pairing())!;
    final wrong = HubPairing(
      hubId: pairing.hubId,
      addresses: pairing.addresses,
      port: pairing.port,
      key: SyncCipher.random().keyBase64,
    );
    await LocalStore(phoneDb).write('sync.pairing', _json(wrong));
    await expectLater(phone.syncNow(), throwsA(isA<SyncException>()));
  });

  test('refuses a phone whose clock is far off', () async {
    await hub.stop();
    hub = await startHub(
      atTime: Clock.fixed(DateTime.now().add(const Duration(hours: 3))),
    );
    // Pairing is checked against the hub clock too.
    final offer = await withClock(
      Clock.fixed(DateTime.now().add(const Duration(hours: 3))),
      hub.createOffer,
    );
    await expectLater(
      phone.pair(offer.code, deviceName: 'Pixel'),
      throwsA(isA<SyncException>()),
    );
  });

  test('rejects sync with a stale timestamp', () async {
    await pairPhone();
    final port = hub.boundPort!;
    await hub.stop();
    final skewed = Clock.fixed(DateTime.now().add(const Duration(hours: 3)));
    hub = await startHub(atTime: skewed, port: port);
    await expectLater(
      phone.syncNow(),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('clocks'),
        ),
      ),
    );
  });

  test('answers unknown paths and methods', () async {
    final base = 'http://127.0.0.1:${hub.boundPort}';
    expect((await http.get(Uri.parse('$base/sync'))).statusCode, 405);
    expect((await http.post(Uri.parse('$base/nope'))).statusCode, 404);
    expect(
      (await http.post(Uri.parse('$base/pair'), body: '{')).statusCode,
      400,
    );
    expect((await http.post(Uri.parse('$base/sync'))).statusCode, 401);
  });

  test('start and stop are idempotent', () async {
    expect(hub.running, isTrue);
    await hub.start();
    await hub.stop();
    expect(hub.running, isFalse);
    expect(hub.boundPort, isNull);
    await hub.start();
    expect(hub.running, isTrue);
  });

  test('keeps the same hub id', () async {
    expect(await hub.hubId(), await hub.hubId());
    final again = SyncHub(db: pcDb, store: LocalStore(pcDb), port: 0);
    expect(await again.hubId(), await hub.hubId());
  });

  test('reports an unreachable hub', () async {
    await pairPhone();
    await hub.stop();
    await expectLater(
      phone.syncNow(),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('Could not reach the PC'),
        ),
      ),
    );
  });

  test('finds a hub that moved, and remembers where', () async {
    await pairPhone();
    final pairing = (await phone.pairing())!;
    // Pretend the stored address is stale.
    await LocalStore(phoneDb).write(
      'sync.pairing',
      _json(
        HubPairing(
          hubId: pairing.hubId,
          addresses: const ['203.0.113.9'],
          port: pairing.port,
          key: pairing.key,
        ),
      ),
    );
    final finder = newClient(
      discover: (id) async {
        expect(id, pairing.hubId);
        return (address: '127.0.0.1', port: hub.boundPort!);
      },
    );
    await finder.syncNow();
    final moved = (await finder.pairing())!;
    expect(moved.addresses.first, '127.0.0.1');
    expect(moved.addresses, contains('203.0.113.9'));
  });

  test('a moved hub that still fails is reported', () async {
    await pairPhone();
    final pairing = (await phone.pairing())!;
    final finder = newClient(
      discover: (_) async => (address: '127.0.0.1', port: 1),
    );
    await LocalStore(phoneDb).write(
      'sync.pairing',
      _json(
        HubPairing(
          hubId: pairing.hubId,
          addresses: const ['203.0.113.9'],
          port: 1,
          key: pairing.key,
        ),
      ),
    );
    await expectLater(finder.syncNow(), throwsA(isA<SyncException>()));
  });

  test('a bad pairing code is a format error', () async {
    await expectLater(
      phone.pair('nonsense', deviceName: 'Pixel'),
      throwsA(isA<FormatException>()),
    );
  });

  test('a hub error status is reported', () async {
    final offer = await hub.createOffer();
    final client = newClient(client: _Fixed(http.Response('nope', 500)));
    await expectLater(
      client.pair(offer.code, deviceName: 'Pixel'),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('500'),
        ),
      ),
    );
  });

  test('an unreadable answer is reported', () async {
    final offer = await hub.createOffer();
    final client = newClient(client: _Fixed(http.Response('garbage', 200)));
    await expectLater(
      client.pair(offer.code, deviceName: 'Pixel'),
      throwsA(isA<SyncException>()),
    );
    await pairPhone();
    final pairing = (await phone.pairing())!;
    final liar = newClient(client: _Fixed(http.Response('garbage', 200)));
    await LocalStore(phoneDb).write('sync.pairing', _json(pairing));
    await expectLater(liar.syncNow(), throwsA(isA<SyncException>()));
  });

  test('syncNow reports the exception text', () {
    expect(const SyncException('x').toString(), 'x');
  });

  group('discovery', () {
    test('a responder answers with the hub id and port', () async {
      final responder = DiscoveryResponder(
        hubId: 'hub-9',
        hubPort: 1234,
        port: 0,
      );
      await responder.start();
      addTearDown(responder.stop);
      final found = await discoverHub(
        'hub-9',
        target: InternetAddress.loopbackIPv4,
        port: responder.boundPort!,
      );
      expect(found, (address: '127.0.0.1', port: 1234));
    });

    test('ignores other hubs and gives up after the timeout', () async {
      final responder = DiscoveryResponder(
        hubId: 'someone-else',
        hubPort: 1,
        port: 0,
      );
      await responder.start();
      addTearDown(responder.stop);
      final found = await discoverHub(
        'hub-9',
        timeout: const Duration(milliseconds: 300),
        target: InternetAddress.loopbackIPv4,
        port: responder.boundPort!,
      );
      expect(found, isNull);
    });

    test('a responder ignores other questions and stops cleanly', () async {
      final responder = DiscoveryResponder(hubId: 'h', hubPort: 1, port: 0);
      expect(responder.boundPort, isNull);
      await responder.start();
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(
        [1, 2, 3],
        InternetAddress.loopbackIPv4,
        responder.boundPort!,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(socket.receive(), isNull);
      socket.close();
      responder.stop();
      expect(responder.boundPort, isNull);
    });

    test('a garbled answer is ignored', () async {
      final fake = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      fake.listen((event) {
        final packet = fake.receive();
        if (packet != null) {
          fake.send([0xff, 0xfe], packet.address, packet.port);
        }
      });
      addTearDown(fake.close);
      final found = await discoverHub(
        'hub-9',
        timeout: const Duration(milliseconds: 300),
        target: InternetAddress.loopbackIPv4,
        port: fake.port,
      );
      expect(found, isNull);
    });
  });

  test('localAddresses lists IPv4 addresses without loopback', () async {
    final addresses = await localAddresses();
    expect(addresses, isNot(contains('127.0.0.1')));
  });

  test('discovery by default asks the whole network', () async {
    final found = await discoverHub(
      'nobody-answers',
      timeout: const Duration(milliseconds: 200),
    );
    expect(found, isNull);
  });

  test('PairedDevice round-trips through JSON', () {
    final device = PairedDevice(
      id: 'd',
      name: 'n',
      key: 'k',
      pairedAt: DateTime.utc(2026),
    ).syncedAt(DateTime.utc(2026, 2));
    final copy = PairedDevice.fromJson(device.toJson());
    expect(copy.lastSyncAt, DateTime.utc(2026, 2));
    expect(copy.pairedAt, DateTime.utc(2026));
  });
}

String _json(HubPairing pairing) => jsonEncode(pairing.toJson());

class _Fixed extends http.BaseClient {
  _Fixed(this.response);

  final http.Response response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(response.bodyBytes),
        response.statusCode,
      );
}
