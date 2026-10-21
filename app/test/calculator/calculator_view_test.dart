import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_data/kina_data.dart';

void main() {
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
