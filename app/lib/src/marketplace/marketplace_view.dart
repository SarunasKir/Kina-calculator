import 'package:decimal/decimal.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_core/kina_core.dart';
import 'package:kina_data/kina_data.dart';
import 'package:meta/meta.dart';

final _million = Decimal.fromInt(1000000);

/// What the marketplace screen shows for a typed price (requirements FR-12,
/// FR-13). Rates, fees and the seller price come from the calculator.
@immutable
class MarketplaceView {
  /// Values the item priced [priceText] with [settings].
  factory MarketplaceView.from(CalculatorSettings settings, String priceText) {
    Decimal kina;
    try {
      kina = parseKina(priceText);
    } on KinaFormatException catch (e) {
      return MarketplaceView._(settings: settings, error: e.message);
    }
    if (kina <= Decimal.zero) {
      return MarketplaceView._(
        settings: settings,
        error: 'Enter a positive Kina price, e.g. 25m, 750k or 25000000',
      );
    }
    final value = evaluateMarket(
      MarketQuote(
        kina: kina,
        qunaPerChest: parseAmount(settings.qunaPerChest),
        kinaPerChest: parseAmount(settings.millionsPerChest) * _million,
        qunaPerPack: parseAmount(settings.qunaPerPack),
        packPrice: parseAmount(settings.packPrice),
        sellerPerMillion: parseAmount(settings.pricePerMillion),
        vatPercent: parseAmount(settings.vatPercent),
        feePercent: parseAmount(settings.payment.feePercent),
        fixedFee: parseAmount(settings.payment.fixedFee),
      ),
    );
    return MarketplaceView._(settings: settings, kina: kina, value: value);
  }

  const MarketplaceView._({
    required this.settings,
    this.kina,
    this.value,
    this.error,
  });

  /// The calculator settings used.
  final CalculatorSettings settings;

  /// The parsed price in raw Kina, when valid.
  final Decimal? kina;

  /// The valuation, when the price is valid.
  final MarketValue? value;

  /// Why the price cannot be valued, if it cannot.
  final String? error;

  /// Whether the item can be saved to the journal.
  bool get canSave => value?.validOfficial ?? false;

  /// Formats [amount] in the calculator currency.
  String money(Decimal amount) => formatMoney(amount, settings.currency);

  /// The comparison sentence, such as "Official is € 3.10 more than RMT".
  String get differenceLine {
    final v = value;
    if (v == null) {
      return '--';
    }
    if (!v.validOfficial) {
      return 'Set valid Quna chest and pack rates on the calculator';
    }
    return v.difference >= Decimal.zero
        ? 'Official route costs ${money(v.difference)} more than RMT'
        : 'RMT costs ${money(-v.difference)} more than the official route';
  }

  /// The journal entry for this item, with values converted to EUR. Only
  /// valid when [canSave].
  JournalEntry entry({
    required String id,
    required DateTime date,
    required String item,
  }) {
    final v = value!;
    final fx = settings.ratesPerEur[settings.currency];
    final rate = fx == null || fx <= Decimal.zero ? Decimal.one : fx;
    Decimal eur(Decimal amount) => roundCents(amount / rate);
    return JournalEntry(
      id: id,
      date: date,
      item: item,
      kina: kina!,
      qunaEquivalent: v.qunaExact,
      officialEur: eur(v.officialExact),
      rmtEur: eur(v.rmt.total),
      currency: settings.currency,
      fxRatePerEur: rate,
    );
  }
}
