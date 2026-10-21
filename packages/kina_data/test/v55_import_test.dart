import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:kina_data/kina_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  late KinaDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('imports all four v55 files', () async {
    final summary = await importV55(
      db,
      settingsJson: fixture('settings.json'),
      profilesJson: fixture('profiles.json'),
      historyJson: fixture('price_history.json'),
      journalJson: fixture('marketplace_purchases.json'),
    );
    expect(summary.settings, isTrue);
    expect(summary.profiles, 2);
    expect(summary.snapshots, 2);
    expect(summary.journalEntries, 2);

    final s = await SettingsRepository(db).load();
    expect(s.amountMillions, '150');
    expect(s.vatPercent, '21');
    expect(s.selectedPayment, 3);
    expect(s.paymentMethods[3].name, 'PayPal');
    expect(s.paymentMethods[3].feePercent, '4.4');
    expect(s.paymentMethods[3].fixedFee, '0.35');
    expect(s.paymentMethods[7].feePercent, '5.9', reason: 'blank uses default');
    expect(s.sellers.map((e) => e.name), ['Alpha', 'Beta', 'Gamma']);
    expect(s.sellers.first.pricePerMillion, '1.10');
    expect(s.currency, 'USD');
    expect(s.targetCurrency, 'GBP');
    expect(s.ratesPerEur['USD'], Decimal.parse('1.0823'));
    expect(s.ratesPerEur['CAD'], Decimal.parse('1.5'));
    expect(s.rateSource, RateSource.ecb);
    expect(s.rateDate, '2026-10-17');

    final profiles = await ProfileRepository(db).list();
    expect(profiles.map((p) => p.name), ['EU marketplace', 'Weekend offer']);
    expect(profiles.last.settings.amountMillions, '500');
    expect(profiles.first.settings.rateSource, RateSource.manual);
    expect(profiles.first.settings.vatPercent, '23.4567');

    final history = await SnapshotRepository(db).list();
    expect(history.first.officialEurPerMillion, Decimal.parse('3.1875'));
    expect(history.last.officialEurPerMillion, isNull);
    expect(history.last.rateDate, '2026-10-07');
    expect(history.first.rateDate, isNull);
    expect(history.last.eurRate, Decimal.parse('1.0823'));
    expect(history.first.sellers[2].eurPerMillion, Decimal.parse('2.5512'));

    final journal = await JournalRepository(db).list();
    expect(journal.last.item, 'Ancient sword');
    expect(journal.last.kina, Decimal.fromInt(25000000));
    expect(journal.last.officialEur, Decimal.parse('95.63'));
    expect(journal.first.item, JournalRepository.unnamedItem);
  });

  test('importing history and journal twice does not duplicate', () async {
    for (var i = 0; i < 2; i++) {
      await importV55(
        db,
        historyJson: fixture('price_history.json'),
        journalJson: fixture('marketplace_purchases.json'),
      );
    }
    expect(await SnapshotRepository(db).list(), hasLength(2));
    expect(await JournalRepository(db).list(), hasLength(2));
  });

  test('skipped files import nothing', () async {
    final summary = await importV55(db);
    expect(summary.settings, isFalse);
    expect(summary.profiles + summary.snapshots + summary.journalEntries, 0);
  });

  test('broken settings fall back to defaults field by field', () {
    final s = settingsFromV55({
      'Amount': 12,
      'Payment': 99,
      'Currency': 7,
      'FX': [1, 0, 1, 1, 1],
      'SellerNames': ['Only one'],
      'RateMode': 'Saved manual rates',
    });
    expect(s.amountMillions, '300');
    expect(s.selectedPayment, 0);
    expect(s.currency, 'EUR');
    expect(s.ratesPerEur, CalculatorSettings.defaults.ratesPerEur);
    expect(s.sellers.first.name, 'Only one');
    expect(s.sellers[1].name, 'Seller B');
    expect(s.rateSource, RateSource.saved);
    expect(s.rateDate, isNull);
  });

  test('numbers in odd shapes become decimals or zero', () {
    final e = journalEntryFromV55({
      'date': '2026-10-05T20:11:00Z',
      'kina': '1000',
      'quna_equivalent': 'not a number',
      'official_eur': null,
    });
    expect(e.kina, Decimal.fromInt(1000));
    expect(e.qunaEquivalent, Decimal.zero);
    expect(e.officialEur, Decimal.zero);
    expect(e.currency, 'EUR');
  });

  test('snapshot with fewer prices than names', () {
    final s = snapshotFromV55({
      'timestamp': '2026-10-01T10:00:00Z',
      'names': ['A', 7],
      'all_in_eur': [1.5],
    });
    expect(s.sellers.map((p) => p.name), ['A', 'Seller 2']);
    expect(s.sellers.last.eurPerMillion, Decimal.zero);
    expect(s.officialEurPerMillion, isNull);
  });

  test('profile without data uses defaults', () async {
    await importV55(db, profilesJson: '[{"Name": "Empty"}]');
    final p = (await ProfileRepository(db).list()).single;
    expect(p.settings.amountMillions, '300');
  });

  test('invalid JSON throws FormatException', () {
    expect(
      () => importV55(db, settingsJson: '{not json'),
      throwsA(isA<FormatException>()),
    );
  });
}
