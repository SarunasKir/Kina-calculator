import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_data/kina_data.dart';

import '../helpers.dart';

void main() {
  late KinaDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<List<JournalEntry>> journal(WidgetTester tester) async =>
      (await tester.runAsync(() => JournalRepository(db).list()))!;

  Future<void> open(WidgetTester tester, {Size? size, FakeFileAccess? files}) =>
      pumpApp(
        tester,
        db,
        size: size ?? const Size(1440, 1180),
        files: files,
      ).then((_) => goTo(tester, 'Marketplace'));

  testWidgets('values the default price with the calculator settings', (
    tester,
  ) async {
    await open(tester);
    expect(textOf(tester, const Key('marketQuna')), contains('7500 Quna'));
    expect(textOf(tester, const Key('marketOfficial')), contains('€ 95.63'));
    expect(
      textOf(tester, const Key('marketChests')),
      contains('13 · 7800 Quna'),
    );
    expect(textOf(tester, const Key('marketWhole')), contains('€ 99.45'));
    expect(textOf(tester, const Key('marketRmt')), contains('€ 33.05'));
    expect(
      textOf(tester, const Key('marketDifference')),
      'Official route costs € 62.58 more than RMT',
    );
    expect(textOf(tester, const Key('journalTotals')), 'No saved items yet');
  });

  testWidgets('shows a hint for an unreadable price and blocks saving', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('marketPrice')), '25 bags');
    await tester.pump();
    expect(
      find.text('Use a positive Kina price, e.g. 25000000 or 25m'),
      findsOneWidget,
    );
    expect(textOf(tester, const Key('marketRmt')), contains('--'));
    final save = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('saveItem')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('says when the Quna setup is invalid', (tester) async {
    await tester.runAsync(
      () => SettingsRepository(
        db,
      ).save(CalculatorSettings.defaults.copyWith(packPrice: '0')),
    );
    await open(tester);
    expect(
      textOf(tester, const Key('marketOfficial')),
      contains('Needs valid Quna rates'),
    );
    expect(textOf(tester, const Key('marketRmt')), contains('€ 33.05'));
  });

  testWidgets('saves, totals, exports and deletes journal entries', (
    tester,
  ) async {
    final files = FakeFileAccess();
    await open(tester, files: files);
    await tester.enterText(find.byKey(const Key('marketItem')), ' Sword ');
    await tester.enterText(find.byKey(const Key('marketPrice')), '50m');
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveItem')));
    await settle(tester);
    await expectSnack(tester, 'Saved to the journal: Sword');
    final saved = await journal(tester);
    expect(saved.single.item, 'Sword');
    expect(saved.single.kina.toString(), '50000000');
    expect(
      textOf(tester, const Key('journalTotals')),
      '1 items · € 191.25 official · € 65.13 RMT',
    );

    await tester.tap(find.byKey(const Key('exportJournal')));
    await settle(tester);
    expect(files.saved.keys.single, startsWith('kina_journal_'));
    expect(files.saved.values.single, contains('Sword,50000000'));
    expect(find.textContaining('CSV saved: /exports/'), findsOneWidget);

    final delete = find.byKey(Key('deleteEntry-${saved.single.id}'));
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(await journal(tester), hasLength(1));

    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDelete')));
    await settle(tester);
    expect(await journal(tester), isEmpty);
    expect(textOf(tester, const Key('journalTotals')), 'No saved items yet');
  });

  testWidgets('reports a failed export', (tester) async {
    final files = FakeFileAccess()..failSave = true;
    await tester.runAsync(
      () => JournalRepository(db).add(
        JournalEntry(
          id: 'a',
          date: DateTime.utc(2026, 10, 20),
          item: 'Shield',
          kina: Decimal.fromInt(1000000),
          qunaEquivalent: Decimal.fromInt(300),
          officialEur: Decimal.one,
          rmtEur: Decimal.one,
          currency: 'EUR',
          fxRatePerEur: Decimal.one,
        ),
      ),
    );
    await open(tester, files: files);
    await tester.tap(find.byKey(const Key('exportJournal')));
    await settle(tester);
    expect(find.textContaining('Export failed'), findsOneWidget);
  });

  testWidgets('phone layout lists the journal under the item', (tester) async {
    await tester.runAsync(
      () => JournalRepository(db).add(
        JournalEntry(
          id: 'a',
          date: DateTime.utc(2026, 10, 20),
          item: 'Shield',
          kina: Decimal.fromInt(1000000),
          qunaEquivalent: Decimal.fromInt(300),
          officialEur: Decimal.one,
          rmtEur: Decimal.one,
          currency: 'EUR',
          fxRatePerEur: Decimal.one,
        ),
      ),
    );
    await open(tester, size: const Size(412, 915));
    await tester.scrollUntilVisible(
      find.text('Shield'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Shield'), findsOneWidget);
  });
}
