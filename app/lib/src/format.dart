import 'package:decimal/decimal.dart';

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
