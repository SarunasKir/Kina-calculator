import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_data/kina_data.dart';

import '../helpers.dart';

void main() {
  late KinaDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<void> open(
    WidgetTester tester,
    String tab, {
    FakeFileAccess? files,
  }) async {
    await pumpApp(tester, db, files: files);
    await goTo(tester, 'Analysis');
    await tester.tap(find.byKey(Key(tab)));
    await settle(tester);
  }

  testWidgets('breakdown explains the current calculation', (tester) async {
    await open(tester, 'breakdownTab');
    expect(find.text('300 million Kina × € 1.00 per 1M'), findsOneWidget);
    expect(find.text('€ 385.80 all-in'), findsOneWidget);
    expect(
      find.text('€ 300.00 + € 70.37 VAT + € 15.43 fee = € 385.80'),
      findsOneWidget,
    );
  });

  testWidgets('profiles save, update, load and delete', (tester) async {
    await open(tester, 'profilesTab');
    expect(find.text('No profiles saved yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('saveProfile')));
    await settle(tester);
    await expectSnack(tester, 'Enter a profile name first');

    await tester.enterText(find.byKey(const Key('profileName')), 'Cheap');
    await tester.tap(find.byKey(const Key('saveProfile')));
    await settle(tester);
    await expectSnack(tester, 'Saved profile: Cheap');
    expect(find.text('Saved profiles (1 of 50)'), findsOneWidget);

    // Change the stored settings; loading the profile restores them.
    await tester.runAsync(
      () => SettingsRepository(
        db,
      ).save(CalculatorSettings.defaults.copyWith(amountMillions: '5')),
    );
    await tester.enterText(find.byKey(const Key('profileName')), 'CHEAP');
    await tester.tap(find.byKey(const Key('saveProfile')));
    await settle(tester);
    await expectSnack(tester, 'Saved profile: CHEAP');
    expect(find.text('Saved profiles (1 of 50)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('loadProfile-CHEAP')));
    await settle(tester);
    await expectSnack(tester, 'Loaded CHEAP into the calculator');
    final loaded = await tester.runAsync(() => SettingsRepository(db).load());
    expect(loaded!.amountMillions, '300');

    await tester.tap(find.byKey(const Key('deleteProfile-CHEAP')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.byKey(const Key('deleteProfile-CHEAP')), findsOneWidget);

    await tester.tap(find.byKey(const Key('deleteProfile-CHEAP')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDelete')));
    await settle(tester);
    expect(find.text('No profiles saved yet'), findsOneWidget);
  });

  testWidgets('profiles report the limits', (tester) async {
    await tester.runAsync(() async {
      final repo = ProfileRepository(db);
      for (var i = 0; i < ProfileRepository.maxProfiles; i++) {
        await repo.save('P$i', CalculatorSettings.defaults);
      }
    });
    await open(tester, 'profilesTab');
    await tester.enterText(find.byKey(const Key('profileName')), 'New one');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    await expectSnack(
      tester,
      'You can keep 50 profiles. Delete an old one first',
    );
  });

  testWidgets('profiles reject long names', (tester) async {
    await open(tester, 'profilesTab');
    // The field caps typing at 42, so set the text directly.
    final field = tester.widget<TextField>(
      find.byKey(const Key('profileName')),
    );
    field.controller!.text = 'x' * 43;
    await tester.tap(find.byKey(const Key('saveProfile')));
    await settle(tester);
    await expectSnack(tester, 'Profile names can be at most 42 characters');
  });

  testWidgets('history saves snapshots, switches series and exports', (
    tester,
  ) async {
    final files = FakeFileAccess();
    await open(tester, 'historyTab', files: files);
    expect(
      find.text('No snapshots yet. Save one to start tracking prices.'),
      findsOneWidget,
    );
    expect(find.text('No prices saved for this series yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('saveSnapshot')));
    await settle(tester);
    expect(find.textContaining('Snapshot saved: '), findsOneWidget);
    final saved = (await tester.runAsync(() => SnapshotRepository(db).list()))!;
    expect(saved.single.sellers.first.eurPerMillion, Decimal.parse('1.286'));
    expect(find.textContaining('1 snapshots · latest'), findsOneWidget);

    await tester.tap(find.byKey(const Key('series')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Official Quna').last);
    await tester.pumpAndSettle();
    expect(find.text('Official Quna'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exportHistory')));
    await settle(tester);
    expect(files.saved.keys.single, startsWith('kina_price_history_'));
    expect(files.saved.values.single, contains('Official Quna EUR per 1M'));
  });

  testWidgets('history explains why a snapshot cannot be saved', (
    tester,
  ) async {
    await tester.runAsync(
      () => SettingsRepository(
        db,
      ).save(CalculatorSettings.defaults.copyWith(amountMillions: '0')),
    );
    await open(tester, 'historyTab');
    await tester.tap(find.byKey(const Key('saveSnapshot')));
    await settle(tester);
    expect(
      find.text('Enter a positive Kina amount before saving a snapshot'),
      findsOneWidget,
    );
  });
}
