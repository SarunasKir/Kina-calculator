import 'package:decimal/decimal.dart';
import 'package:kina_core/kina_core.dart';
import 'package:rational/rational.dart';
import 'package:test/test.dart';

Rational r(int n, int d) => Rational(BigInt.from(n), BigInt.from(d));

void main() {
  test('roundCents rounds half away from zero', () {
    expect(roundCents(r(12345, 1000)), Decimal.parse('12.35'));
    expect(roundCents(r(-12345, 1000)), Decimal.parse('-12.35'));
  });

  test('toScale rounds to the scale, half away from zero', () {
    expect(toScale(r(38580, 33000), 4), Decimal.parse('1.1691'));
    expect(toScale(r(1, 3), 4), Decimal.parse('0.3333'));
    expect(toScale(r(5, 100000), 4), Decimal.parse('0.0001'));
    expect(toScale(r(-5, 100000), 4), Decimal.parse('-0.0001'));
    expect(toScale(r(7, 2), 0), Decimal.fromInt(4));
  });

  test('nonNegative turns negatives into zero', () {
    expect(nonNegative(Decimal.parse('-1')), Decimal.zero);
    expect(nonNegative(Decimal.one), Decimal.one);
  });
}
