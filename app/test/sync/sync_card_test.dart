import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/providers.dart';
import 'package:kina_app/src/sync/sync_providers.dart';
import 'package:kina_data/kina_data.dart';
import 'package:kina_sync/kina_sync.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../helpers.dart';

void main() {
  late KinaDatabase pcDb;
  late KinaDatabase phoneDb;

  setUpAll(() {
    // The test binding answers every HTTP request with 400; these tests talk
    // to a real hub on this machine.
    HttpOverrides.global = null;
  });

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    pcDb = memoryDatabase();
    phoneDb = memoryDatabase();
  });
  tearDown(() async {
    await pcDb.close();
    await phoneDb.close();
  });

  Future<void> openMore(WidgetTester tester) => goTo(tester, 'More');

  group('on the PC', () {
    testWidgets('switches the hub on, adds a phone and lists it', (
      tester,
    ) async {
      final hub = testHub(pcDb);
      await pumpApp(tester, pcDb, role: SyncRole.hub, hub: hub);
      await openMore(tester);
      expect(find.byKey(const Key('addPhone')), findsNothing);
      expect(hub.running, isFalse);

      await tester.tap(find.byKey(const Key('hubSwitch')));
      await settleNetwork(tester);
      expect(hub.running, isTrue);
      expect(
        await tester.runAsync(() => LocalStore(pcDb).read('sync.hubEnabled')),
        '1',
      );

      await tester.tap(find.byKey(const Key('addPhone')));
      await settleNetwork(tester);
      expect(find.byType(QrImageView), findsOneWidget);
      final code = tester
          .widget<SelectableText>(find.byKey(const Key('pairingCode')))
          .data!;
      expect(code, startsWith(pairingPrefix));
      await tester.tap(find.byKey(const Key('copyCode')));
      await tester.pump();

      // A real phone pairs and syncs with the code.
      await JournalRepository(phoneDb).add(
        JournalEntry(
          id: 'j',
          date: DateTime.utc(2026, 10, 20),
          item: 'Phone sword',
          kina: Decimal.fromInt(1000000),
          qunaEquivalent: Decimal.fromInt(300),
          officialEur: Decimal.one,
          rmtEur: Decimal.one,
          currency: 'EUR',
          fxRatePerEur: Decimal.one,
        ),
      );
      final phone = testClient(phoneDb);
      await tester.runAsync(() async {
        await phone.pair(code, deviceName: 'Pixel 8');
        await phone.syncNow();
      });
      await tester.tap(find.byKey(const Key('closeOffer')));
      await settleNetwork(tester);
      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.textContaining('Last synced'), findsOneWidget);

      // The PC's journal now has the phone's entry on screen.
      await goTo(tester, 'Marketplace');
      expect(find.text('Phone sword'), findsOneWidget);
      await openMore(tester);

      // Removing the phone asks first, then it cannot sync any more.
      final id = (await tester.runAsync(hub.devices))!.single.id;
      await tester.tap(find.byKey(Key('removeDevice-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await settleNetwork(tester);
      expect(find.text('Pixel 8'), findsOneWidget);
      await tester.tap(find.byKey(Key('removeDevice-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await settleNetwork(tester);
      expect(find.text('Pixel 8'), findsNothing);
      final refused = await tester.runAsync(() async {
        try {
          await phone.syncNow();
          return null;
        } on SyncException catch (e) {
          return e.message;
        }
      });
      expect(refused, contains('no longer paired'));

      await tester.tap(find.byKey(const Key('hubSwitch')));
      await settleNetwork(tester);
      expect(hub.running, isFalse);
    });

    testWidgets('starts the hub when the app opens if it was on', (
      tester,
    ) async {
      await tester.runAsync(
        () => LocalStore(pcDb).write('sync.hubEnabled', '1'),
      );
      final hub = testHub(pcDb);
      await pumpApp(tester, pcDb, role: SyncRole.hub, hub: hub);
      await settleNetwork(tester);
      expect(hub.running, isTrue);
      await openMore(tester);
      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('hubSwitch')),
      );
      expect(toggle.value, isTrue);
    });
  });

  group('on a phone', () {
    Future<(SyncHub, String)> startPc() async {
      final hub = testHub(pcDb);
      await hub.start();
      addTearDown(hub.stop);
      return (hub, (await hub.createOffer()).code);
    }

    testWidgets('pairs with a code and syncs', (tester) async {
      final (hub, code) = (await tester.runAsync(startPc))!;
      await tester.runAsync(
        () => SettingsRepository(
          pcDb,
        ).save(CalculatorSettings.defaults.copyWith(amountMillions: '42')),
      );
      await pumpApp(tester, phoneDb);
      await openMore(tester);
      expect(find.byKey(const Key('syncNow')), findsNothing);

      await tester.enterText(find.byKey(const Key('pairingInput')), code);
      await tester.tap(find.byKey(const Key('pair')));
      await waitFor(tester, find.textContaining('Paired and synced'));
      expect(find.byKey(const Key('pairedText')), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byKey(const Key('pairedText'))),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      expect((await tester.runAsync(hub.devices))!.single.name, 'Test phone');

      // The PC's settings arrived on the phone, and show on the calculator.
      await goTo(tester, 'Calculator');
      expect(find.widgetWithText(TextField, '42'), findsOneWidget);
      await openMore(tester);

      await tester.tap(find.byKey(const Key('syncNow')));
      await waitFor(tester, find.textContaining('Synced: '));

      // Unpairing asks first.
      await tester.tap(find.byKey(const Key('unpair')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pairedText')), findsOneWidget);
      await tester.tap(find.byKey(const Key('unpair')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await settleNetwork(tester);
      expect(find.byKey(const Key('pairingInput')), findsOneWidget);
    });

    testWidgets('explains a bad code and an unreachable PC', (tester) async {
      await pumpApp(tester, phoneDb);
      await openMore(tester);
      await tester.enterText(find.byKey(const Key('pairingInput')), 'hello');
      await tester.tap(find.byKey(const Key('pair')));
      await settleNetwork(tester);
      expect(find.text('This is not a Kina pairing code'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byKey(const Key('pair'))),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();

      final code = PairingOffer.create(
        hubId: 'gone',
        addresses: const ['127.0.0.1'],
        port: 1,
      ).code;
      await tester.enterText(find.byKey(const Key('pairingInput')), code);
      await tester.tap(find.byKey(const Key('pair')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not reach the PC'), findsOneWidget);
    });

    testWidgets('pastes the code from the clipboard', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData'
            ? <String, Object?>{'text': '  kina1:abc  '}
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(tester, phoneDb);
      await openMore(tester);
      await tester.tap(find.byKey(const Key('pasteCode')));
      await tester.pumpAndSettle();
      expect(find.text('kina1:abc'), findsOneWidget);
    });

    // The startup sync runs outside the widget tester, where real sockets
    // and the test clock do not fight.
    test('syncs quietly when the app opens', () async {
      final (hub, code) = await startPc();
      await testClient(phoneDb).pair(code, deviceName: 'Test phone');
      await ProfileRepository(
        pcDb,
      ).save('From PC', CalculatorSettings.defaults);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(phoneDb),
          syncClientProvider.overrideWithValue(testClient(phoneDb)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pairingProvider.notifier).autoSync();

      expect(
        [for (final p in await ProfileRepository(phoneDb).list()) p.name],
        ['From PC'],
      );
      expect(hub.running, isTrue);
    });

    test('an unreachable PC on open is not an error', () async {
      final (hub, code) = await startPc();
      await testClient(phoneDb).pair(code, deviceName: 'Test phone');
      await hub.stop();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(phoneDb),
          syncClientProvider.overrideWithValue(testClient(phoneDb)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pairingProvider.notifier).autoSync();
    });

    test('opening the app unpaired does nothing', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(phoneDb),
          syncClientProvider.overrideWithValue(testClient(phoneDb)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pairingProvider.notifier).autoSync();
      expect(await container.read(pairingProvider.future), isNull);
    });
  });
}
