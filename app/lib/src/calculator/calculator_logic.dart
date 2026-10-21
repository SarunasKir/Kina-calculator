import 'package:decimal/decimal.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_core/kina_core.dart';
import 'package:kina_data/kina_data.dart';

/// Builds the calculation input from [settings], optionally at another
/// seller [rate].
PurchaseInput purchaseInput(CalculatorSettings settings, {Decimal? rate}) =>
    PurchaseInput(
      millions: parseAmount(settings.amountMillions),
      ratePerMillion: rate ?? parseAmount(settings.pricePerMillion),
      vatPercent: parseAmount(settings.vatPercent),
      feePercent: parseAmount(settings.payment.feePercent),
      fixedFee: parseAmount(settings.payment.fixedFee),
      qunaPerPack: parseAmount(settings.qunaPerPack),
      packPrice: parseAmount(settings.packPrice),
      qunaPerChest: parseAmount(settings.qunaPerChest),
      millionsPerChest: parseAmount(settings.millionsPerChest),
    );

/// The rate table stored in [settings].
ExchangeRates ratesOf(CalculatorSettings settings) =>
    ExchangeRates(settings.ratesPerEur);

/// Multiplies every money input by [factor]: seller prices, the pack price
/// and every payment method's fixed fee. Percentages and Quna figures are
/// unit-less and stay as they are.
CalculatorSettings revalueMoney(CalculatorSettings s, Decimal factor) {
  String scale(String text) => formatInput(parseAmount(text) * factor);
  return s.copyWith(
    pricePerMillion: scale(s.pricePerMillion),
    packPrice: scale(s.packPrice),
    paymentMethods: [
      for (final m in s.paymentMethods) m.copyWith(fixedFee: scale(m.fixedFee)),
    ],
    sellers: [
      for (final seller in s.sellers)
        Seller(
          name: seller.name,
          pricePerMillion: scale(seller.pricePerMillion),
        ),
    ],
  );
}

/// Switches the calculator currency, keeping every amount's EUR value
/// (requirement FR-9).
CalculatorSettings changeCurrency(CalculatorSettings s, String next) {
  if (next == s.currency) {
    return s;
  }
  final factor = ratesOf(s).revalueFactor(s.currency, next);
  return revalueMoney(s, factor).copyWith(currency: next);
}

/// Applies a typed exchange rate between the calculator and target currency
/// (requirement FR-10). Returns [s] unchanged for an invalid rate.
CalculatorSettings setManualRate(CalculatorSettings s, String text) {
  final value = parseAmount(text);
  final before = ratesOf(s);
  final after = before.withPair(s.currency, s.targetCurrency, value);
  if (after == null) {
    return s;
  }
  final factor = toScale(
    after.rate(s.currency)!.toRational() /
        before.rate(s.currency)!.toRational(),
    10,
  );
  return revalueMoney(
    s,
    factor,
  ).copyWith(ratesPerEur: after.perEur, rateSource: RateSource.manual);
}

/// Applies rates synced from the ECB (requirement FR-11), keeping every
/// amount's EUR value.
CalculatorSettings applySyncedRates(
  CalculatorSettings s,
  Map<String, Decimal> perEur,
  String publishedOn,
) {
  final next = ExchangeRates(perEur);
  final old = ratesOf(s).rate(s.currency);
  final updated = next.rate(s.currency);
  final factor = old != null && updated != null
      ? toScale(updated.toRational() / old.toRational(), 10)
      : Decimal.one;
  return revalueMoney(s, factor).copyWith(
    ratesPerEur: next.perEur,
    rateSource: RateSource.ecb,
    rateDate: publishedOn,
  );
}
