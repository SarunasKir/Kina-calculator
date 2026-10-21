import 'package:decimal/decimal.dart';
import 'package:kina_core/kina_core.dart';
import 'package:test/test.dart';

Decimal d(String s) => Decimal.parse(s);

void main() {
  final rates = ExchangeRates({
    'USD': d('1.10'),
    'GBP': d('0.87'),
    'CAD': d('1.5'),
    'AUD': d('1.6'),
  });

  test('EUR is always 1', () {
    expect(rates.rate('EUR'), Decimal.one);
    expect(ExchangeRates({'EUR': d('2')}).rate('EUR'), Decimal.one);
  });

  test('defaults match v55', () {
    expect(ExchangeRates.defaults.rate('USD'), d('1.10'));
    expect(ExchangeRates.defaults.rate('AUD'), d('1.67'));
  });

  test('convert round trip', () {
    final usd = rates.convert(d('24.9756'), 'EUR', 'USD');
    expect(rates.convert(usd, 'USD', 'EUR'), d('24.9756'));
  });

  test('unknown currency leaves the value unchanged', () {
    expect(rates.convert(d('5'), 'EUR', 'XXX'), d('5'));
    expect(rates.pair('EUR', 'XXX'), isNull);
    expect(rates.rate('XXX'), isNull);
  });

  test('pair shows one unit of from in to', () {
    expect(rates.pair('USD', 'GBP'), d('0.790909'));
  });

  group('withPair (v55 SetPair)', () {
    test('foreign to EUR sets the inverse', () {
      expect(rates.withPair('USD', 'EUR', d('0.8'))!.rate('USD'), d('1.25'));
    });

    test('EUR to foreign sets directly', () {
      expect(rates.withPair('EUR', 'GBP', d('0.95'))!.rate('GBP'), d('0.95'));
    });

    test('cross pair moves the target', () {
      final next = rates.withPair('USD', 'GBP', d('0.9'))!;
      expect(next.rate('GBP'), d('0.99'));
      expect(next.rate('EUR'), Decimal.one);
    });

    test('rejects identity, zero and unknown pairs', () {
      expect(rates.withPair('EUR', 'EUR', d('1.2')), isNull);
      expect(rates.withPair('EUR', 'USD', d('0')), isNull);
      expect(rates.withPair('XXX', 'USD', d('1')), isNull);
    });
  });

  test('revalue factor keeps EUR value', () {
    expect(rates.revalueFactor('EUR', 'USD'), d('1.1'));
  });
}
