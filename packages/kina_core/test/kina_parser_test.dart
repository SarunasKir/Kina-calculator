import 'package:decimal/decimal.dart';
import 'package:kina_core/kina_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseKina accepts', () {
    const cases = {
      '25m': '25000000',
      '750k': '750000',
      '2.5m': '2500000',
      '1000000': '1000000',
      '1,5b': '1500000000',
      ' 25 M ': '25000000',
      '1,250,000': '1250000',
      '1.250.000': '1250000',
      '1b': '1000000000',
      '.5m': '500000',
      '1,250': '1250',
      '1.250': '1250',
      '999.999': '999999',
      '1.250m': '1250000',
      '1,250k': '1250',
      '12,5': '12.5',
      '1.5': '1.5',
      '0.250': '0.25',
    };
    cases.forEach((text, expected) {
      test('"$text" as $expected', () {
        expect(parseKina(text), Decimal.parse(expected));
      });
    });
  });

  group('parseKina rejects', () {
    for (final text in ['', '-20m', 'bad', 'NaN', '1e999', '2000000000000m']) {
      test('"$text"', () {
        expect(() => parseKina(text), throwsA(isA<KinaFormatException>()));
      });
    }
  });

  test('irregular groups are not treated as thousands', () {
    expect(() => parseKina('12,34,567'), throwsA(isA<KinaFormatException>()));
    expect(() => parseKina('1.2.3'), throwsA(isA<KinaFormatException>()));
  });
}
