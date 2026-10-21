@Tags(['golden'])
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/app.dart';
import 'package:kina_app/src/sync/sync_providers.dart';
import 'package:kina_data/kina_data.dart';

import '../helpers.dart';

Future<void> golden(
  WidgetTester tester, {
  required Size size,
  required double pixelRatio,
  required Brightness brightness,
  required String name,
  String? page,
  String? tab,
  SyncRole role = SyncRole.phone,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final db = memoryDatabase();
  addTearDown(() => tester.runAsync(db.close));
  await tester.runAsync(
    () => SettingsRepository(
      db,
    ).save(CalculatorSettings.defaults.copyWith(vatPercent: '21')),
  );
  await tester.runAsync(() => seed(db));
  await pumpApp(tester, db, size: size * pixelRatio, role: role);
  tester.view.devicePixelRatio = pixelRatio;
  await tester.pumpAndSettle();
  if (page != null) {
    await tester.tap(find.text(page).last);
    await tester.pumpAndSettle();
  }
  if (tab != null) {
    await tester.tap(find.byKey(Key(tab)));
    await tester.pumpAndSettle();
  }
  await expectLater(find.byType(KinaApp), matchesGoldenFile('$name.png'));
}

/// Fixed journal entries and snapshots so the other pages have content.
Future<void> seed(KinaDatabase db) async {
  final journal = JournalRepository(db);
  final items = [
    ('Ancient Greatsword', '25000000', '7500', '95.63', '30.38'),
    ('Sky Wing Mount', '120000000', '36000', '459.00', '145.02'),
    ('Enchantment Stones x50', '8000000', '2400', '30.60', '10.02'),
  ];
  for (var i = 0; i < items.length; i++) {
    final (name, kina, quna, official, rmt) = items[i];
    await journal.add(
      JournalEntry(
        id: 'entry-$i',
        date: DateTime.utc(2026, 10, 18 + i, 19, 30),
        item: name,
        kina: Decimal.parse(kina),
        qunaEquivalent: Decimal.parse(quna),
        officialEur: Decimal.parse(official),
        rmtEur: Decimal.parse(rmt),
        currency: 'EUR',
        fxRatePerEur: Decimal.one,
      ),
    );
  }
  final snapshots = SnapshotRepository(db);
  const prices = [1.31, 1.28, 1.35, 1.22, 1.19, 1.24, 1.17, 1.21, 1.14];
  final days = [0, 2, 3, 6, 8, 9, 13, 16, 20];
  for (var i = 0; i < prices.length; i++) {
    Decimal price(double factor) =>
        Decimal.parse((prices[i] * factor).toStringAsFixed(4));
    await snapshots.add(
      PriceSnapshot(
        id: 'snapshot-$i',
        takenAt: DateTime.utc(2026, 10).add(Duration(days: days[i])),
        currency: 'EUR',
        eurRate: Decimal.one,
        rateSource: 'Saved rates',
        millions: Decimal.fromInt(300),
        sellers: [
          SnapshotPrice(name: 'Seller A', eurPerMillion: price(1)),
          SnapshotPrice(name: 'Seller B', eurPerMillion: price(1.5)),
          SnapshotPrice(name: 'Seller C', eurPerMillion: price(2)),
        ],
        officialEurPerMillion: Decimal.parse('3.825'),
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'Windows, light',
    (t) => golden(
      t,
      size: const Size(1440, 1180),
      pixelRatio: 1,
      brightness: Brightness.light,
      name: 'windows_light',
    ),
  );
  testWidgets(
    'Windows, dark',
    (t) => golden(
      t,
      size: const Size(1440, 1180),
      pixelRatio: 1,
      brightness: Brightness.dark,
      name: 'windows_dark',
    ),
  );
  testWidgets(
    'phone, light',
    (t) => golden(
      t,
      size: const Size(412, 915),
      pixelRatio: 2,
      brightness: Brightness.light,
      name: 'phone_light',
    ),
  );
  testWidgets(
    'phone, dark',
    (t) => golden(
      t,
      size: const Size(412, 915),
      pixelRatio: 2,
      brightness: Brightness.dark,
      name: 'phone_dark',
    ),
  );

  for (final (page, tab, file) in [
    ('Marketplace', null, 'marketplace'),
    ('Analysis', 'historyTab', 'history'),
    ('More', null, 'more'),
  ]) {
    testWidgets(
      '$page, Windows',
      (t) => golden(
        t,
        size: const Size(1440, 1180),
        pixelRatio: 1,
        brightness: Brightness.light,
        name: 'windows_$file',
        page: page,
        tab: tab,
        // The PC is the sync hub; the phone pairs with it.
        role: SyncRole.hub,
      ),
    );
    testWidgets(
      '$page, phone',
      (t) => golden(
        t,
        size: const Size(412, 915),
        pixelRatio: 2,
        brightness: Brightness.dark,
        name: 'phone_$file',
        page: page,
        tab: tab,
      ),
    );
  }
}
