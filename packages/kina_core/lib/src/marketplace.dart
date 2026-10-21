import 'package:decimal/decimal.dart';
import 'package:kina_core/src/money.dart';
import 'package:kina_core/src/purchase.dart';
import 'package:meta/meta.dart';
import 'package:rational/rational.dart';

/// Inputs for valuing one marketplace item priced in Kina.
@immutable
class MarketQuote {
  /// Creates a quote. Negative values are rejected by [evaluateMarket].
  const MarketQuote({
    required this.kina,
    required this.qunaPerChest,
    required this.kinaPerChest,
    required this.qunaPerPack,
    required this.packPrice,
    required this.sellerPerMillion,
    required this.vatPercent,
    required this.feePercent,
    required this.fixedFee,
  });

  /// Item price in raw Kina (not millions).
  final Decimal kina;

  /// Quna paid for one Kina chest.
  final Decimal qunaPerChest;

  /// Kina in one chest, raw (not millions).
  final Decimal kinaPerChest;

  /// Quna in one official shop pack.
  final Decimal qunaPerPack;

  /// Real-money price of one official shop pack.
  final Decimal packPrice;

  /// RMT seller price per one million Kina.
  final Decimal sellerPerMillion;

  /// VAT percentage.
  final Decimal vatPercent;

  /// Payment fee percentage.
  final Decimal feePercent;

  /// Fixed payment fee.
  final Decimal fixedFee;

  List<Decimal> get _values => [
    kina,
    qunaPerChest,
    kinaPerChest,
    qunaPerPack,
    packPrice,
    sellerPerMillion,
    vatPercent,
    feePercent,
    fixedFee,
  ];
}

/// The value of a marketplace item (requirement CALC-4).
@immutable
class MarketValue {
  /// Creates a market value.
  const MarketValue({
    required this.validOfficial,
    required this.qunaExact,
    required this.chestCount,
    required this.qunaWholeChests,
    required this.officialExact,
    required this.officialWholeChests,
    required this.rmt,
  });

  /// Whether all official Quna inputs are above zero.
  final bool validOfficial;

  /// Proportional Quna equivalent (6 decimal places).
  final Decimal qunaExact;

  /// Whole chests needed to cover the price.
  final int chestCount;

  /// Quna paid when buying whole chests.
  final Decimal qunaWholeChests;

  /// Official money value of [qunaExact].
  final Decimal officialExact;

  /// Official money value of [qunaWholeChests].
  final Decimal officialWholeChests;

  /// RMT cost of the same Kina.
  final RmtCost rmt;

  /// Official exact value minus RMT total.
  Decimal get difference => officialExact - rmt.total;
}

/// Thrown when a marketplace quote contains a negative value.
class InvalidQuoteException implements Exception {
  @override
  String toString() => 'Negative or invalid marketplace value';
}

/// Values a marketplace item in Quna, official money and RMT money.
///
/// Throws [InvalidQuoteException] if any input is negative.
MarketValue evaluateMarket(MarketQuote quote) {
  if (quote._values.any((v) => v < Decimal.zero)) {
    throw InvalidQuoteException();
  }
  final validOfficial =
      quote.kinaPerChest > Decimal.zero &&
      quote.qunaPerChest > Decimal.zero &&
      quote.qunaPerPack > Decimal.zero &&
      quote.packPrice > Decimal.zero;

  var qunaExact = Rational.zero;
  var chests = 0;
  var qunaWhole = Decimal.zero;
  var officialExact = Decimal.zero;
  var officialWhole = Decimal.zero;

  if (validOfficial) {
    final chestShare = quote.kina / quote.kinaPerChest;
    qunaExact = chestShare * quote.qunaPerChest.toRational();
    chests = chestShare.ceil().toInt();
    qunaWhole = Decimal.fromInt(chests) * quote.qunaPerChest;
    final perQuna = quote.packPrice / quote.qunaPerPack;
    officialExact = roundCents(qunaExact * perQuna);
    officialWhole = roundCents(qunaWhole.toRational() * perQuna);
  }

  final rmt = rmtCost(
    millions: toScale(quote.kina.toRational() / Rational.fromInt(1000000), 12),
    ratePerMillion: quote.sellerPerMillion,
    vatPercent: quote.vatPercent,
    feePercent: quote.feePercent,
    fixedFee: quote.fixedFee,
  );

  return MarketValue(
    validOfficial: validOfficial,
    qunaExact: toScale(qunaExact, 6),
    chestCount: chests,
    qunaWholeChests: qunaWhole,
    officialExact: officialExact,
    officialWholeChests: officialWhole,
    rmt: rmt,
  );
}
