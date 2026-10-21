import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/format.dart';

Decimal d(String s) => Decimal.parse(s);

void main() {
  test('money uses the currency symbol and two decimals', () {
    expect(formatMoney(d('1147.5'), 'EUR'), '€ 1147.50');
    expect(formatMoney(d('2'), 'CAD'), r'C$ 2.00');
    expect(formatMoney(d('2'), 'SEK'), 'SEK 2.00');
  });

  test('Quna and percent', () {
    expect(formatQuna(d('7500.4')), '7500 Quna');
    expect(formatPercent(d('52.549')), '52.5%');
  });

  test('parseAmount reads like v55', () {
    expect(parseAmount(' 1,5 '), d('1.5'));
    expect(parseAmount('2.25'), d('2.25'));
    expect(parseAmount(''), Decimal.zero);
    expect(parseAmount('abc'), Decimal.zero);
    expect(parseAmount('-3'), Decimal.zero);
  });

  test('formatInput trims trailing zeros', () {
    expect(formatInput(d('1.100000')), '1.1');
    expect(formatInput(d('1.0000001')), '1');
    expect(formatInput(d('3')), '3');
    expect(formatInput(d('0.1234567')), '0.123457');
    expect(formatInput(d('12.5'), scale: 0), '13');
  });
}
