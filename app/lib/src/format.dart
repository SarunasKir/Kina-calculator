import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:kina_core/kina_core.dart';

/// Symbols for the currencies the app knows; others show their code.
const currencySymbols = {
  'EUR': '€',
  'USD': r'$',
  'GBP': '£',
  'CAD': r'C$',
  'AUD': r'A$',
};

/// Display names for the currency pickers.
const currencyNames = {
  'EUR': 'Euro',
  'USD': 'US Dollar',
  'GBP': 'British Pound',
  'CAD': 'Canadian Dollar',
  'AUD': 'Australian Dollar',
};

/// Formats [value] as money in [currency], such as `€ 12.34`.
String formatMoney(Decimal value, String currency) =>
    '${currencySymbols[currency] ?? currency} ${value.toStringAsFixed(2)}';

/// Formats a Quna amount as a whole number, such as `7500 Quna`.
String formatQuna(Decimal value) => '${value.toStringAsFixed(0)} Quna';

/// Formats a percentage with one decimal place, such as `52.5%`.
String formatPercent(Decimal value) => '${value.toStringAsFixed(1)}%';

/// Reads a typed number the way v55 does: a comma counts as a decimal point,
/// and anything blank, invalid or negative counts as zero.
Decimal parseAmount(String text) {
  final value = Decimal.tryParse(text.trim().replaceAll(',', '.'));
  return value == null || value < Decimal.zero ? Decimal.zero : value;
}

final _compactSuffix = RegExp(r'[kmb]$', caseSensitive: false);

/// Reads an amount of Kina in millions. Plain numbers are already millions
/// (`300`, `1,5`); compact notation works as in the marketplace, so `1.5b` is
/// 1500 and `500k` is 0.5. Anything unreadable counts as zero.
Decimal parseMillions(String text) {
  final trimmed = text.trim();
  if (!_compactSuffix.hasMatch(trimmed)) {
    return parseAmount(trimmed);
  }
  try {
    return parseKina(trimmed).shift(-6);
  } on KinaFormatException {
    return Decimal.zero;
  }
}

/// A short message when [text] is not a readable number, or null when it is
/// fine. Blank is allowed and counts as zero. With [compact], `300m` style
/// notation is accepted too.
String? numberError(String text, {bool compact = false}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (compact && _compactSuffix.hasMatch(trimmed)) {
    try {
      parseKina(trimmed);
      return null;
    } on KinaFormatException {
      return 'Use a number such as 300 or 1.5b';
    }
  }
  return Decimal.tryParse(trimmed.replaceAll(',', '.')) == null
      ? 'Enter a number such as 12.5'
      : null;
}

/// Writes [value] with at most [scale] decimals and no trailing zeros, for
/// putting a recalculated amount back into a text field.
String formatInput(Decimal value, {int scale = 6}) {
  final fixed = value.round(scale: scale).toStringAsFixed(scale);
  if (!fixed.contains('.')) {
    return fixed;
  }
  final trimmed = fixed.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith('.')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}

final _grouped = NumberFormat('#,##0', 'en_US');
final _dateTime = DateFormat('yyyy-MM-dd HH:mm');

/// Formats raw Kina with thousands separators, such as `25,000,000 Kina`.
String formatKina(Decimal value) =>
    '${_grouped.format(value.round().toBigInt().toInt())} Kina';

/// Formats a local date and time, such as `2026-10-21 10:15`.
String formatDateTime(DateTime value) => _dateTime.format(value.toLocal());
