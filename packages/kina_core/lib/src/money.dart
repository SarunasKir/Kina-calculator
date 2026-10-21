import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

final Rational _hundred = Rational.fromInt(100);

/// Rounds [value] to whole cents, half away from zero.
///
/// v55 rounds every displayed step to cents, so the rebuild does the same.
Decimal roundCents(Rational value) =>
    Decimal.fromBigInt((value * _hundred).round()).shift(-2);

/// Returns [value], or zero when it is negative.
///
/// v55 treats negative inputs as zero rather than rejecting the whole
/// calculation, so a half-typed field never blanks every result.
Decimal nonNegative(Decimal value) =>
    value < Decimal.zero ? Decimal.zero : value;

/// Rounds an exact [Rational] to a [Decimal] with at most [scale] decimal
/// places, half away from zero.
Decimal toScale(Rational value, int scale) => Decimal.fromBigInt(
  (value * Rational(BigInt.from(10).pow(scale))).round(),
).shift(-scale);
