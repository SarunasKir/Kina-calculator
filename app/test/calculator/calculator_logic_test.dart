import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/calculator/calculator_logic.dart';
import 'package:kina_data/kina_data.dart';

Decimal d(String s) => Decimal.parse(s);

void main() {
  final base = CalculatorSettings.defaults;

  test('purchaseInput reads every field and the selected fees', () {
    final input = purchaseInput(base.copyWith(selectedPayment: 3));
    expect(input.millions, d('300'));
    expect(input.ratePerMillion, d('1'));
    expect(input.vatPercent, d('23.4567'));
    expect(input.feePercent, d('5.9'));
    expect(input.fixedFee, Decimal.zero);
    expect(input.qunaPerPack, d('4000'));
    expect(input.packPrice, d('51'));
    expect(input.qunaPerChest, d('600'));
    expect(input.millionsPerChest, d('2'));
    expect(purchaseInput(base, rate: d('7')).ratePerMillion, d('7'));
  });

  group('changeCurrency', () {
    test('revalues every money input and keeps the rest', () {
      final usd = changeCurrency(base, 'USD');
      expect(usd.currency, 'USD');
      expect(usd.pricePerMillion, '1.1');
      expect(usd.packPrice, '56.1');
      expect(usd.paymentMethods.first.fixedFee, '1.089');
      expect(usd.paymentMethods.last.fixedFee, '0');
      expect(usd.sellers.map((s) => s.pricePerMillion), ['1.1', '1.65', '2.2']);
      expect(usd.sellers.first.name, 'Seller A');
      expect(usd.vatPercent, base.vatPercent);
      expect(usd.qunaPerPack, base.qunaPerPack);
      expect(usd.paymentMethods.first.feePercent, '3.9');
    });

    test('round trip returns the same amounts', () {
      final back = changeCurrency(changeCurrency(base, 'GBP'), 'EUR');
      expect(back.packPrice, '51');
      expect(back.sellers.last.pricePerMillion, '2');
    });

    test('same currency is a no-op', () {
      expect(identical(changeCurrency(base, 'EUR'), base), isTrue);
    });
  });

  group('setManualRate', () {
    test('EUR to USD sets the USD rate without revaluing', () {
      final s = setManualRate(base, '1.2');
      expect(s.ratesPerEur['USD'], d('1.2'));
      expect(s.rateSource, RateSource.manual);
      expect(s.packPrice, '51');
    });

    test('a foreign calculator currency revalues money', () {
      final usd = changeCurrency(base, 'USD').copyWith(targetCurrency: 'EUR');
      final s = setManualRate(usd, '0.8');
      expect(s.ratesPerEur['USD'], d('1.25'));
      // 56.1 USD at 1.10 is 51 EUR; at 1.25 it is 63.75 USD.
      expect(s.packPrice, '63.75');
    });

    test('invalid rates change nothing', () {
      expect(identical(setManualRate(base, '0'), base), isTrue);
      expect(identical(setManualRate(base, 'abc'), base), isTrue);
      final same = base.copyWith(targetCurrency: 'EUR');
      expect(identical(setManualRate(same, '2'), same), isTrue);
    });
  });

  group('applySyncedRates', () {
    test('stores ECB rates and keeps EUR value', () {
      final usd = changeCurrency(base, 'USD');
      final s = applySyncedRates(usd, {
        'USD': d('1.2'),
        'GBP': d('0.9'),
      }, '2026-10-20');
      expect(s.rateSource, RateSource.ecb);
      expect(s.rateDate, '2026-10-20');
      expect(s.ratesPerEur['USD'], d('1.2'));
      expect(s.ratesPerEur['EUR'], Decimal.one);
      expect(s.packPrice, '61.2');
    });

    test('a currency missing from the reply is not revalued', () {
      final cad = changeCurrency(base, 'CAD');
      final s = applySyncedRates(cad, {'USD': d('1.2')}, '2026-10-20');
      expect(s.packPrice, cad.packPrice);
    });
  });
}
