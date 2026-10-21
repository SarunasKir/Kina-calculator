import 'package:decimal/decimal.dart';
import 'package:kina_core/src/money.dart';
import 'package:meta/meta.dart';
import 'package:rational/rational.dart';

/// Everything needed to price an RMT purchase against the official Quna shop.
///
/// Money values are in the calculator currency. Negative values are treated
/// as zero.
@immutable
class PurchaseInput {
  /// Creates a purchase input. All values default to zero.
  PurchaseInput({
    Decimal? millions,
    Decimal? ratePerMillion,
    Decimal? vatPercent,
    Decimal? feePercent,
    Decimal? fixedFee,
    Decimal? qunaPerPack,
    Decimal? packPrice,
    Decimal? qunaPerChest,
    Decimal? millionsPerChest,
  }) : millions = nonNegative(millions ?? Decimal.zero),
       ratePerMillion = nonNegative(ratePerMillion ?? Decimal.zero),
       vatPercent = nonNegative(vatPercent ?? Decimal.zero),
       feePercent = nonNegative(feePercent ?? Decimal.zero),
       fixedFee = nonNegative(fixedFee ?? Decimal.zero),
       qunaPerPack = nonNegative(qunaPerPack ?? Decimal.zero),
       packPrice = nonNegative(packPrice ?? Decimal.zero),
       qunaPerChest = nonNegative(qunaPerChest ?? Decimal.zero),
       millionsPerChest = nonNegative(millionsPerChest ?? Decimal.zero);

  /// Kina bought, in millions.
  final Decimal millions;

  /// Seller price for one million Kina.
  final Decimal ratePerMillion;

  /// VAT percentage applied to the seller subtotal.
  final Decimal vatPercent;

  /// Payment fee percentage, applied to subtotal plus VAT.
  final Decimal feePercent;

  /// Fixed payment fee, charged once per purchase.
  final Decimal fixedFee;

  /// Quna in one official shop pack.
  final Decimal qunaPerPack;

  /// Real-money price of one official shop pack.
  final Decimal packPrice;

  /// Quna paid for one Kina chest.
  final Decimal qunaPerChest;

  /// Kina in one chest, in millions.
  final Decimal millionsPerChest;

  /// Returns a copy with a different seller price, for seller comparisons.
  PurchaseInput withRate(Decimal rate) => PurchaseInput(
    millions: millions,
    ratePerMillion: rate,
    vatPercent: vatPercent,
    feePercent: feePercent,
    fixedFee: fixedFee,
    qunaPerPack: qunaPerPack,
    packPrice: packPrice,
    qunaPerChest: qunaPerChest,
    millionsPerChest: millionsPerChest,
  );
}

/// The RMT cost breakdown (requirement CALC-1).
@immutable
class RmtCost {
  /// Creates a cost breakdown.
  const RmtCost({
    required this.subtotal,
    required this.vat,
    required this.fee,
    required this.total,
  });

  /// Seller price times quantity.
  final Decimal subtotal;

  /// VAT on the subtotal.
  final Decimal vat;

  /// Payment processing fee.
  final Decimal fee;

  /// All-in RMT cost.
  final Decimal total;
}

/// Prices an RMT purchase of [millions] at [ratePerMillion], including VAT
/// and payment fees (requirement CALC-1).
RmtCost rmtCost({
  required Decimal millions,
  required Decimal ratePerMillion,
  required Decimal vatPercent,
  required Decimal feePercent,
  required Decimal fixedFee,
}) {
  final hundred = Decimal.fromInt(100);
  final subtotal = roundCents((millions * ratePerMillion).toRational());
  final vat = roundCents(subtotal * vatPercent / hundred);
  final fee = roundCents(
    (subtotal + vat) * feePercent / hundred + fixedFee.toRational(),
  );
  final total = roundCents((subtotal + vat + fee).toRational());
  return RmtCost(subtotal: subtotal, vat: vat, fee: fee, total: total);
}

/// The full RMT versus official comparison (requirements CALC-1 to CALC-3).
@immutable
class PurchaseResult {
  /// Creates a result.
  const PurchaseResult({
    required this.rmt,
    required this.officialValid,
    required this.qunaRequired,
    required this.officialCost,
    required this.savings,
    required this.savingsPercent,
    required this.effectiveRate,
    required this.breakEvenRate,
  });

  /// RMT cost breakdown.
  final RmtCost rmt;

  /// Whether all official Quna inputs are above zero.
  final bool officialValid;

  /// Quna needed for the same Kina (6 decimal places).
  final Decimal qunaRequired;

  /// Real-money cost of that Quna through official packs.
  final Decimal officialCost;

  /// Official cost minus RMT total; positive means RMT is cheaper.
  final Decimal savings;

  /// Savings as a percentage of official cost (4 decimal places).
  final Decimal savingsPercent;

  /// RMT total divided by millions bought (6 decimal places).
  final Decimal effectiveRate;

  /// Seller price per 1M at which RMT costs the same as official
  /// (6 decimal places).
  final Decimal breakEvenRate;
}

/// Compares an RMT purchase with the official Quna route.
PurchaseResult evaluatePurchase(PurchaseInput input) {
  final rmt = rmtCost(
    millions: input.millions,
    ratePerMillion: input.ratePerMillion,
    vatPercent: input.vatPercent,
    feePercent: input.feePercent,
    fixedFee: input.fixedFee,
  );
  final officialValid =
      input.millionsPerChest > Decimal.zero &&
      input.qunaPerPack > Decimal.zero &&
      input.qunaPerChest > Decimal.zero &&
      input.packPrice > Decimal.zero;

  var quna = Rational.zero;
  var official = Decimal.zero;
  var savings = Decimal.zero;
  var savingsPercent = Decimal.zero;
  var breakEven = Decimal.zero;
  final hundred = Rational.fromInt(100);

  if (officialValid) {
    quna =
        (input.millions * input.qunaPerChest).toRational() /
        input.millionsPerChest.toRational();
    official = roundCents(
      quna / input.qunaPerPack.toRational() * input.packPrice.toRational(),
    );
    savings = roundCents((official - rmt.total).toRational());
    if (official > Decimal.zero) {
      savingsPercent = toScale(
        savings.toRational() / official.toRational() * hundred,
        4,
      );
    }
    final denominator =
        input.millions.toRational() *
        (Rational.one + input.vatPercent.toRational() / hundred) *
        (Rational.one + input.feePercent.toRational() / hundred);
    if (denominator > Rational.zero) {
      final raw = (official - input.fixedFee).toRational() / denominator;
      breakEven = raw > Rational.zero ? toScale(raw, 6) : Decimal.zero;
    }
  }

  final effective = input.millions > Decimal.zero
      ? toScale(rmt.total.toRational() / input.millions.toRational(), 6)
      : Decimal.zero;

  return PurchaseResult(
    rmt: rmt,
    officialValid: officialValid,
    qunaRequired: toScale(quna, 6),
    officialCost: official,
    savings: savings,
    savingsPercent: savingsPercent,
    effectiveRate: effective,
    breakEvenRate: breakEven,
  );
}
