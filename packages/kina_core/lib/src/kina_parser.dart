import 'package:decimal/decimal.dart';

/// Thrown when text cannot be read as a Kina amount.
class KinaFormatException extends FormatException {
  /// Creates the exception with a user-facing [message].
  const KinaFormatException(super.message);
}

final Decimal _maxKina = Decimal.parse('1e15');
final RegExp _plainNumber = RegExp(r'^\d+(\.\d+)?$|^\.\d+$|^\d+\.$');

/// Parses a Kina amount such as `25m`, `750k`, `1.5b`, `1,250,000` or
/// `1.250.000` into raw Kina.
///
/// Matches v55: a single comma is a decimal separator (`1,5m`), and two or
/// more separators in groups of three are thousands separators. Negative
/// numbers, scientific notation and values above 10^15 are rejected.
Decimal parseKina(String text) {
  var s = text.trim().toLowerCase().replaceAll(' ', '');
  if (s.isEmpty) {
    throw const KinaFormatException('Enter a Kina amount');
  }
  var multiplier = Decimal.one;
  const suffixes = {'k': '1000', 'm': '1000000', 'b': '1000000000'};
  final suffix = suffixes[s[s.length - 1]];
  if (suffix != null) {
    multiplier = Decimal.parse(suffix);
    s = s.substring(0, s.length - 1);
  }

  final commas = ','.allMatches(s).length;
  final dots = '.'.allMatches(s).length;
  if (commas >= 2 && dots == 0) {
    s = _ungroup(s, ',');
  } else if (dots >= 2 && commas == 0) {
    s = _ungroup(s, '.');
  } else if (commas == 1 && dots == 0) {
    s = s.replaceAll(',', '.');
  }

  const error = KinaFormatException(
    'Use a positive Kina price, e.g. 25000000 or 25m',
  );
  if (!_plainNumber.hasMatch(s)) {
    throw error;
  }
  final value = Decimal.parse(s) * multiplier;
  if (value > _maxKina) {
    throw error;
  }
  return value;
}

/// Removes [separator] when it splits [s] into thousands groups.
String _ungroup(String s, String separator) {
  final parts = s.split(separator);
  final grouped =
      parts.first.isNotEmpty &&
      parts.first.length <= 3 &&
      parts.skip(1).every((p) => p.length == 3);
  return grouped ? parts.join() : s;
}
