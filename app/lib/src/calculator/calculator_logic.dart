import 'package:decimal/decimal.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_core/kina_core.dart';
import 'package:kina_data/kina_data.dart';

/// Builds the calculation input from [settings], optionally at another
/// seller [rate]. A [seller]'s site fees are added to the payment method's.
PurchaseInput purchaseInput(
  CalculatorSettings settings, {
  Decimal? rate,
  Seller? seller,
}) => PurchaseInput(
  millions: parseMillions(settings.amountMillions),
  ratePerMillion: rate ?? parseAmount(settings.pricePerMillion),
  vatPercent: parseAmount(settings.vatPercent),
  feePercent:
      parseAmount(settings.payment.feePercent) +
      (seller == null ? Decimal.zero : parseAmount(seller.extraFeePercent)),
  fixedFee:
      parseAmount(settings.payment.fixedFee) +
      (seller == null ? Decimal.zero : parseAmount(seller.extraFixedFee)),
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
        seller.copyWith(
          pricePerMillion: scale(seller.pricePerMillion),
          extraFixedFee: scale(seller.extraFixedFee),
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

/// The longest payment method name.
const maxPaymentNameLength = 30;

/// Index of the selected payment method, or 0 if the stored index is stale.
int selectedIndex(CalculatorSettings s) =>
    s.selectedPayment >= 0 && s.selectedPayment < s.paymentMethods.length
    ? s.selectedPayment
    : 0;

/// Adds a seller named "Seller N" with the last seller's price, up to the
/// limit.
CalculatorSettings addSeller(CalculatorSettings s) {
  if (s.sellers.length >= CalculatorSettings.maxSellers) {
    return s;
  }
  return s.copyWith(
    sellers: [
      ...s.sellers,
      Seller(
        name: 'Seller ${s.sellers.length + 1}',
        pricePerMillion: s.sellers.last.pricePerMillion,
      ),
    ],
  );
}

/// Removes the seller at [index], keeping at least one.
CalculatorSettings removeSeller(CalculatorSettings s, int index) {
  if (s.sellers.length <= CalculatorSettings.minSellers) {
    return s;
  }
  return s.copyWith(sellers: [...s.sellers]..removeAt(index));
}

String _cleanName(String name) {
  final trimmed = name.trim();
  return trimmed.length > maxPaymentNameLength
      ? trimmed.substring(0, maxPaymentNameLength)
      : trimmed;
}

/// Adds a payment method with no fees yet and selects it. A blank name
/// changes nothing.
CalculatorSettings addPaymentMethod(CalculatorSettings s, String name) {
  final clean = _cleanName(name);
  if (clean.isEmpty) {
    return s;
  }
  return s.copyWith(
    paymentMethods: [
      ...s.paymentMethods,
      PaymentMethod(name: clean, feePercent: '0', fixedFee: '0'),
    ],
    selectedPayment: s.paymentMethods.length,
  );
}

/// Renames the selected payment method. A blank name changes nothing.
CalculatorSettings renamePaymentMethod(CalculatorSettings s, String name) {
  final clean = _cleanName(name);
  if (clean.isEmpty) {
    return s;
  }
  final methods = [...s.paymentMethods];
  final i = selectedIndex(s);
  methods[i] = methods[i].copyWith(name: clean);
  return s.copyWith(paymentMethods: methods);
}

/// Removes the selected payment method, keeping at least one.
CalculatorSettings removePaymentMethod(CalculatorSettings s) {
  if (s.paymentMethods.length <= 1) {
    return s;
  }
  return s.copyWith(
    paymentMethods: [...s.paymentMethods]..removeAt(selectedIndex(s)),
    selectedPayment: 0,
  );
}
