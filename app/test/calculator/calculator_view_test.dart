import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_data/kina_data.dart';

void main() {
  cheapestTests();
  final base = CalculatorSettings.defaults.copyWith(vatPercent: '21');

  test('main result and savings line', () {
    final v = CalculatorView.from(base);
    expect(v.main.rmt.total, Decimal.parse('378.15'));
    expect(v.savingsLine, 'You save € 769.35 with RMT (67.0%)');
    expect(v.hasAmount, isTrue);
    expect(v.pairRate, Decimal.parse('1.1'));
  });

  test('RMT dearer than official', () {
    final v = CalculatorView.from(base.copyWith(pricePerMillion: '10'));
    expect(v.savingsLine, startsWith('RMT costs € '));
    expect(v.sellerLine(v.sellers.first), 'Total € 378.15 · Save € 769.35');
    final dear = CalculatorView.from(
      base.copyWith(
        sellers: const [Seller(name: 'X', pricePerMillion: '9')],
      ),
    );
    expect(dear.sellerLine(dear.sellers.single), startsWith('Total € 3395.40'));
    expect(dear.sellerLine(dear.sellers.single), contains('Extra €'));
  });

  test('invalid Quna setup', () {
    final v = CalculatorView.from(base.copyWith(qunaPerChest: '0'));
    expect(v.savingsLine, 'Enter valid Quna trade details to compare');
    expect(
      v.sellerLine(v.sellers.first),
      endsWith('Official Quna price unavailable'),
    );
  });

  test('zero amount and unknown target currency', () {
    final v = CalculatorView.from(
      base.copyWith(amountMillions: '', targetCurrency: 'XXX'),
    );
    expect(v.hasAmount, isFalse);
    expect(v.pairRate, isNull);
    expect(v.money(Decimal.one), '€ 1.00');
  });
}

void cheapestTests() {
  group('cheapest seller', () {
    test('names the cheapest and the gap to the next', () {
      final v = CalculatorView.from(CalculatorSettings.defaults);
      expect(
        v.cheapestLine,
        'Cheapest: Seller A · Total € 385.80 · € 192.42 less than Seller B',
      );
    });

    test('site fees can change the winner', () {
      final s = CalculatorSettings.defaults.copyWith(
        sellers: const [
          Seller(name: 'A', pricePerMillion: '1', extraFixedFee: '500'),
          Seller(name: 'B', pricePerMillion: '1.2'),
        ],
      );
      expect(CalculatorView.from(s).cheapestLine, startsWith('Cheapest: B'));
    });

    test('ties and a lone seller', () {
      final s = CalculatorSettings.defaults.copyWith(
        sellers: const [
          Seller(name: 'A', pricePerMillion: '1'),
          Seller(name: 'B', pricePerMillion: '1'),
        ],
      );
      expect(CalculatorView.from(s).cheapestLine, endsWith('same as B'));
      expect(
        CalculatorView.from(
          s.copyWith(sellers: [s.sellers.first]),
        ).cheapestLine,
        isNull,
      );
    });
  });
}
