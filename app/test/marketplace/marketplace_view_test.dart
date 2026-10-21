import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/marketplace/marketplace_view.dart';
import 'package:kina_data/kina_data.dart';

Decimal d(String s) => Decimal.parse(s);

void main() {
  final defaults = CalculatorSettings.defaults;

  test('values a valid price with the calculator settings', () {
    final view = MarketplaceView.from(defaults, '25m');
    expect(view.error, isNull);
    expect(view.kina, d('25000000'));
    final v = view.value!;
    expect(v.qunaExact, d('7500'));
    expect(v.chestCount, 13);
    expect(v.qunaWholeChests, d('7800'));
    expect(v.officialExact, d('95.63'));
    expect(v.officialWholeChests, d('99.45'));
    expect(v.rmt.total, d('33.05'));
    expect(view.canSave, isTrue);
    expect(view.differenceLine, 'Official route costs € 62.58 more than RMT');
  });

  test('says when RMT costs more', () {
    final view = MarketplaceView.from(
      defaults.copyWith(pricePerMillion: '10'),
      '25m',
    );
    expect(
      view.differenceLine,
      'RMT costs € 226.04 more than the official '
      'route',
    );
  });

  test('shows the parser hint for unreadable prices', () {
    final view = MarketplaceView.from(defaults, 'lots');
    expect(view.error, 'Use a positive Kina price, e.g. 25000000 or 25m');
    expect(view.value, isNull);
    expect(view.canSave, isFalse);
    expect(view.differenceLine, '--');
    expect(MarketplaceView.from(defaults, '').error, 'Enter a Kina amount');
  });

  test('rejects a zero price', () {
    expect(MarketplaceView.from(defaults, '0').error, startsWith('Enter a'));
  });

  test('cannot save without valid Quna rates', () {
    final view = MarketplaceView.from(defaults.copyWith(packPrice: '0'), '1m');
    expect(view.value, isNotNull);
    expect(view.canSave, isFalse);
    expect(view.differenceLine, startsWith('Set valid Quna'));
  });

  test('journal entry converts values to EUR', () {
    final usd = defaults.copyWith(currency: 'USD');
    final entry = MarketplaceView.from(
      usd,
      '25m',
    ).entry(id: 'x', date: DateTime.utc(2026), item: 'Sword');
    expect(entry.kina, d('25000000'));
    expect(entry.qunaEquivalent, d('7500'));
    expect(entry.officialEur, d('86.94'));
    expect(entry.rmtEur, d('30.05'));
    expect(entry.currency, 'USD');
    expect(entry.fxRatePerEur, d('1.10'));
  });

  test('journal entry treats a missing rate as 1', () {
    final odd = defaults.copyWith(
      currency: 'JPY',
      ratesPerEur: {'EUR': Decimal.one},
    );
    final entry = MarketplaceView.from(
      odd,
      '25m',
    ).entry(id: 'x', date: DateTime.utc(2026), item: 'Sword');
    expect(entry.fxRatePerEur, Decimal.one);
    expect(entry.officialEur, d('95.63'));
  });
}
