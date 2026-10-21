import 'package:decimal/decimal.dart';
import 'package:kina_core/src/money.dart';
import 'package:meta/meta.dart';

/// Exchange rates stored as units of each currency per 1 EUR
/// (requirement CALC-5). EUR is always exactly 1.
@immutable
class ExchangeRates {
  /// Creates a rate table. [perEur] must not include EUR; it is added as 1.
  ExchangeRates(Map<String, Decimal> perEur)
    : perEur = Map.unmodifiable({...perEur, eur: Decimal.one});

  /// The base currency code.
  static const eur = 'EUR';

  /// v55 default manual rates.
  static final ExchangeRates defaults = ExchangeRates({
    'USD': Decimal.parse('1.10'),
    'GBP': Decimal.parse('0.87'),
    'CAD': Decimal.parse('1.52'),
    'AUD': Decimal.parse('1.67'),
  });

  /// Units per 1 EUR, keyed by ISO currency code.
  final Map<String, Decimal> perEur;

  /// The rate for [code], or null when unknown or not positive.
  Decimal? rate(String code) {
    final r = perEur[code];
    return r != null && r > Decimal.zero ? r : null;
  }

  /// Converts [value] from currency [from] to [to].
  ///
  /// Returns [value] unchanged when either rate is missing, as v55 does.
  Decimal convert(Decimal value, String from, String to, {int scale = 6}) {
    final a = rate(from);
    final b = rate(to);
    if (a == null || b == null) {
      return value;
    }
    return toScale(value.toRational() * b.toRational() / a.toRational(), scale);
  }

  /// How many [to] one unit of [from] buys (shown in the exchange-rate field).
  Decimal? pair(String from, String to, {int scale = 6}) {
    final a = rate(from);
    final b = rate(to);
    if (a == null || b == null) {
      return null;
    }
    return toScale(b / a, scale);
  }

  /// Returns rates updated so that 1 [from] = [value] [to].
  ///
  /// If EUR is one side, the other rate is set directly; otherwise the [to]
  /// rate moves and [from] stays fixed. Returns null for an invalid pair.
  ExchangeRates? withPair(String from, String to, Decimal value) {
    if (from == to || value <= Decimal.zero) {
      return null;
    }
    final a = rate(from);
    if (a == null || rate(to) == null) {
      return null;
    }
    final next = Map<String, Decimal>.of(perEur);
    if (from == eur) {
      next[to] = value;
    } else if (to == eur) {
      next[from] = toScale(Decimal.one / value, 10);
    } else {
      next[to] = a * value;
    }
    return ExchangeRates(next..remove(eur));
  }

  /// Factor that keeps an amount's EUR value when the display currency
  /// changes from [from] to [to].
  Decimal revalueFactor(String from, String to) =>
      convert(Decimal.one, from, to, scale: 10);
}
