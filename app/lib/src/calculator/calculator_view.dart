import 'package:decimal/decimal.dart';
import 'package:kina_app/src/calculator/calculator_logic.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_core/kina_core.dart';
import 'package:kina_data/kina_data.dart';
import 'package:meta/meta.dart';

/// One seller row's outcome (requirement FR-6).
@immutable
class SellerOutcome {
  /// Creates a seller outcome.
  const SellerOutcome({required this.seller, required this.result});

  /// The seller as entered.
  final Seller seller;

  /// The full comparison at this seller's price.
  final PurchaseResult result;
}

/// Everything the calculator screen shows, derived from the settings.
@immutable
class CalculatorView {
  /// Derives the view from [settings].
  factory CalculatorView.from(CalculatorSettings settings) {
    return CalculatorView._(
      settings: settings,
      main: evaluatePurchase(purchaseInput(settings)),
      sellers: [
        for (final s in settings.sellers)
          SellerOutcome(
            seller: s,
            result: evaluatePurchase(
              purchaseInput(
                settings,
                rate: parseAmount(s.pricePerMillion),
                seller: s,
              ),
            ),
          ),
      ],
      pairRate: ratesOf(
        settings,
      ).pair(settings.currency, settings.targetCurrency),
    );
  }

  const CalculatorView._({
    required this.settings,
    required this.main,
    required this.sellers,
    required this.pairRate,
  });

  /// The settings this view was derived from.
  final CalculatorSettings settings;

  /// The comparison at the main seller price.
  final PurchaseResult main;

  /// The comparison for each seller.
  final List<SellerOutcome> sellers;

  /// One calculator currency in the target currency, if both rates are known.
  final Decimal? pairRate;

  /// Formats [value] in the calculator currency.
  String money(Decimal value) => formatMoney(value, settings.currency);

  /// The savings sentence, such as "You save € 201.00 with RMT (52.5%)".
  String get savingsLine {
    if (!main.officialValid) {
      return 'Enter valid Quna trade details to compare';
    }
    if (main.savings >= Decimal.zero) {
      return 'You save ${money(main.savings)} with RMT '
          '(${formatPercent(main.savingsPercent)})';
    }
    return 'RMT costs ${money(-main.savings)} more '
        '(${formatPercent(-main.savingsPercent)})';
  }

  /// Whether the Kina amount is above zero.
  bool get hasAmount => parseMillions(settings.amountMillions) > Decimal.zero;

  /// The cheapest seller by total cost, such as "Cheapest: A · Total € 181.50
  /// · € 20.00 less than B". Null with one seller.
  String? get cheapestLine {
    if (sellers.length < 2) {
      return null;
    }
    final ranked = [...sellers]
      ..sort((a, b) => a.result.rmt.total.compareTo(b.result.rmt.total));
    final best = ranked.first;
    final gap = ranked[1].result.rmt.total - best.result.rmt.total;
    final tail = gap > Decimal.zero
        ? ' · ${money(gap)} less than ${ranked[1].seller.name}'
        : ' · same as ${ranked[1].seller.name}';
    return 'Cheapest: ${best.seller.name} · '
        'Total ${money(best.result.rmt.total)}$tail';
  }

  /// The seller row's summary, such as "Total € 181.50 · Save € 201.00".
  String sellerLine(SellerOutcome outcome) {
    final r = outcome.result;
    final total = 'Total ${money(r.rmt.total)}';
    if (!r.officialValid) {
      return '$total · Official Quna price unavailable';
    }
    final diff = r.officialCost - r.rmt.total;
    return diff >= Decimal.zero
        ? '$total · Save ${money(diff)}'
        : '$total · Extra ${money(-diff)}';
  }
}

/// The rate source line under the currency fields.
String rateStatus(CalculatorSettings s) => switch (s.rateSource) {
  RateSource.ecb => 'ECB via Frankfurter · published ${s.rateDate ?? '?'}',
  RateSource.manual =>
    s.rateDate == null
        ? 'Manual rate'
        : 'Manual rate · last sync ${s.rateDate}',
  RateSource.saved => 'Saved rates · internet needed to sync',
};
