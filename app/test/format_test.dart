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

  test('parseMillions takes plain numbers as millions and reads suffixes', () {
    expect(parseMillions('300'), d('300'));
    expect(parseMillions(' 1,5 '), d('1.5'));
    expect(parseMillions('1.5b'), d('1500'));
    expect(parseMillions('500K'), d('0.5'));
    expect(parseMillions('300m'), d('300'));
    expect(parseMillions('1.2.3m'), Decimal.zero);
  });

  test('numberError explains unreadable numbers', () {
    expect(numberError(''), isNull);
    expect(numberError(' 12,5 '), isNull);
    expect(numberError('1.2.3'), 'Enter a number such as 12.5');
    expect(numberError('.'), 'Enter a number such as 12.5');
    expect(numberError('300m'), 'Enter a number such as 12.5');
    expect(numberError('300m', compact: true), isNull);
    expect(
      numberError('1.2.3m', compact: true),
      'Use a number such as 300 or 1.5b',
    );
    expect(numberError('1.2.3', compact: true), isNotNull);
  });

  test('formatInput trims trailing zeros', () {
    expect(formatInput(d('1.100000')), '1.1');
    expect(formatInput(d('1.0000001')), '1');
    expect(formatInput(d('3')), '3');
    expect(formatInput(d('0.1234567')), '0.123457');
    expect(formatInput(d('12.5'), scale: 0), '13');
  });
}
