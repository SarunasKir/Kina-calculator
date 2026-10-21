import 'package:decimal/decimal.dart';
import 'package:meta/meta.dart';

/// A payment method with its own fee profile (requirement FR-5).
@immutable
class PaymentMethod {
  /// Creates a payment method. Fees are kept as typed text.
  const PaymentMethod({
    required this.name,
    required this.feePercent,
    required this.fixedFee,
  });

  /// Reads a payment method from [json].
  factory PaymentMethod.fromJson(Map<String, Object?> json) => PaymentMethod(
    name: json['name']! as String,
    feePercent: json['feePercent']! as String,
    fixedFee: json['fixedFee']! as String,
  );

  /// Display name, such as "PayPal".
  final String name;

  /// Fee percentage as typed.
  final String feePercent;

  /// Fixed fee as typed, in the calculator currency.
  final String fixedFee;

  /// Returns a copy with the given fields replaced.
  PaymentMethod copyWith({String? feePercent, String? fixedFee}) =>
      PaymentMethod(
        name: name,
        feePercent: feePercent ?? this.feePercent,
        fixedFee: fixedFee ?? this.fixedFee,
      );

  /// Converts to JSON.
  Map<String, Object?> toJson() => {
    'name': name,
    'feePercent': feePercent,
    'fixedFee': fixedFee,
  };

  @override
  bool operator ==(Object other) =>
      other is PaymentMethod &&
      other.name == name &&
      other.feePercent == feePercent &&
      other.fixedFee == fixedFee;

  @override
  int get hashCode => Object.hash(name, feePercent, fixedFee);
}

/// A named seller in the comparison table (requirement FR-6).
@immutable
class Seller {
  /// Creates a seller.
  const Seller({required this.name, required this.pricePerMillion});

  /// Reads a seller from [json].
  factory Seller.fromJson(Map<String, Object?> json) => Seller(
    name: json['name']! as String,
    pricePerMillion: json['pricePerMillion']! as String,
  );

  /// Seller name.
  final String name;

  /// Price per one million Kina, as typed.
  final String pricePerMillion;

  /// Converts to JSON.
  Map<String, Object?> toJson() => {
    'name': name,
    'pricePerMillion': pricePerMillion,
  };

  @override
  bool operator ==(Object other) =>
      other is Seller &&
      other.name == name &&
      other.pricePerMillion == pricePerMillion;

  @override
  int get hashCode => Object.hash(name, pricePerMillion);
}

/// Where the current exchange rates came from.
enum RateSource {
  /// The built-in or previously saved manual rates.
  saved,

  /// The user typed a rate.
  manual,

  /// Synced from the ECB via Frankfurter.
  ecb,
}

/// Every value on the calculator screen. Numbers are stored as typed text so
/// a half-typed field survives a restart.
@immutable
class CalculatorSettings {
  /// Creates settings.
  const CalculatorSettings({
    required this.amountMillions,
    required this.pricePerMillion,
    required this.vatPercent,
    required this.qunaPerPack,
    required this.packPrice,
    required this.qunaPerChest,
    required this.millionsPerChest,
    required this.paymentMethods,
    required this.selectedPayment,
    required this.sellers,
    required this.currency,
    required this.targetCurrency,
    required this.ratesPerEur,
    required this.rateSource,
    this.rateDate,
  });

  /// Reads settings from [json], falling back to [defaults] per field.
  factory CalculatorSettings.fromJson(Map<String, Object?> json) {
    final d = CalculatorSettings.defaults;
    String text(String key, String fallback) =>
        json[key] is String ? json[key]! as String : fallback;
    final methods = (json['paymentMethods'] as List<Object?>?)
        ?.map((e) => PaymentMethod.fromJson(e! as Map<String, Object?>))
        .toList();
    final sellers = (json['sellers'] as List<Object?>?)
        ?.map((e) => Seller.fromJson(e! as Map<String, Object?>))
        .toList();
    final rates = (json['ratesPerEur'] as Map<String, Object?>?)?.map(
      (k, v) => MapEntry(k, Decimal.parse(v! as String)),
    );
    return CalculatorSettings(
      amountMillions: text('amountMillions', d.amountMillions),
      pricePerMillion: text('pricePerMillion', d.pricePerMillion),
      vatPercent: text('vatPercent', d.vatPercent),
      qunaPerPack: text('qunaPerPack', d.qunaPerPack),
      packPrice: text('packPrice', d.packPrice),
      qunaPerChest: text('qunaPerChest', d.qunaPerChest),
      millionsPerChest: text('millionsPerChest', d.millionsPerChest),
      paymentMethods: methods ?? d.paymentMethods,
      selectedPayment: json['selectedPayment'] as int? ?? d.selectedPayment,
      sellers: sellers ?? d.sellers,
      currency: text('currency', d.currency),
      targetCurrency: text('targetCurrency', d.targetCurrency),
      ratesPerEur: rates ?? d.ratesPerEur,
      rateSource:
          RateSource.values.asNameMap()[json['rateSource']] ?? d.rateSource,
      rateDate: json['rateDate'] as String?,
    );
  }

  /// The v55 defaults.
  static final CalculatorSettings defaults = CalculatorSettings(
    amountMillions: '300',
    pricePerMillion: '1.00',
    vatPercent: '23.4567',
    qunaPerPack: '4000',
    packPrice: '51',
    qunaPerChest: '600',
    millionsPerChest: '2',
    paymentMethods: const [
      PaymentMethod(
        name: 'Visa / Mastercard',
        feePercent: '3.9',
        fixedFee: '0.99',
      ),
      PaymentMethod(name: 'Google Pay', feePercent: '3.9', fixedFee: '0.99'),
      PaymentMethod(name: 'Klarna', feePercent: '3.9', fixedFee: '0.99'),
      PaymentMethod(name: 'PayPal', feePercent: '5.9', fixedFee: '0'),
      PaymentMethod(name: 'iDEAL', feePercent: '5.9', fixedFee: '0'),
      PaymentMethod(name: 'Skrill', feePercent: '5.9', fixedFee: '0'),
      PaymentMethod(name: 'Crypto', feePercent: '5.9', fixedFee: '0'),
      PaymentMethod(name: 'Other', feePercent: '5.9', fixedFee: '0'),
    ],
    selectedPayment: 0,
    sellers: const [
      Seller(name: 'Seller A', pricePerMillion: '1.00'),
      Seller(name: 'Seller B', pricePerMillion: '1.50'),
      Seller(name: 'Seller C', pricePerMillion: '2.00'),
    ],
    currency: 'EUR',
    targetCurrency: 'USD',
    ratesPerEur: {
      'EUR': Decimal.one,
      'USD': Decimal.parse('1.10'),
      'GBP': Decimal.parse('0.87'),
      'CAD': Decimal.parse('1.52'),
      'AUD': Decimal.parse('1.67'),
    },
    rateSource: RateSource.saved,
  );

  /// Kina to buy, in millions.
  final String amountMillions;

  /// Main RMT seller price per 1M.
  final String pricePerMillion;

  /// VAT percentage.
  final String vatPercent;

  /// Quna in one official pack.
  final String qunaPerPack;

  /// Price of one official pack.
  final String packPrice;

  /// Quna paid for one Kina chest.
  final String qunaPerChest;

  /// Kina in one chest, in millions.
  final String millionsPerChest;

  /// Payment methods with their fees.
  final List<PaymentMethod> paymentMethods;

  /// Index into [paymentMethods].
  final int selectedPayment;

  /// Sellers in the comparison table.
  final List<Seller> sellers;

  /// Calculator currency code.
  final String currency;

  /// Convert-to currency code.
  final String targetCurrency;

  /// Units of each currency per 1 EUR.
  final Map<String, Decimal> ratesPerEur;

  /// Where [ratesPerEur] came from.
  final RateSource rateSource;

  /// ECB publication date, or last sync date, if any.
  final String? rateDate;

  /// Returns a copy with the given fields replaced. Pass [clearRateDate] to
  /// remove the rate date.
  CalculatorSettings copyWith({
    String? amountMillions,
    String? pricePerMillion,
    String? vatPercent,
    String? qunaPerPack,
    String? packPrice,
    String? qunaPerChest,
    String? millionsPerChest,
    List<PaymentMethod>? paymentMethods,
    int? selectedPayment,
    List<Seller>? sellers,
    String? currency,
    String? targetCurrency,
    Map<String, Decimal>? ratesPerEur,
    RateSource? rateSource,
    String? rateDate,
    bool clearRateDate = false,
  }) => CalculatorSettings(
    amountMillions: amountMillions ?? this.amountMillions,
    pricePerMillion: pricePerMillion ?? this.pricePerMillion,
    vatPercent: vatPercent ?? this.vatPercent,
    qunaPerPack: qunaPerPack ?? this.qunaPerPack,
    packPrice: packPrice ?? this.packPrice,
    qunaPerChest: qunaPerChest ?? this.qunaPerChest,
    millionsPerChest: millionsPerChest ?? this.millionsPerChest,
    paymentMethods: paymentMethods ?? this.paymentMethods,
    selectedPayment: selectedPayment ?? this.selectedPayment,
    sellers: sellers ?? this.sellers,
    currency: currency ?? this.currency,
    targetCurrency: targetCurrency ?? this.targetCurrency,
    ratesPerEur: ratesPerEur ?? this.ratesPerEur,
    rateSource: rateSource ?? this.rateSource,
    rateDate: clearRateDate ? null : rateDate ?? this.rateDate,
  );

  /// The selected payment method, or the first one if the index is stale.
  PaymentMethod get payment =>
      paymentMethods[selectedPayment >= 0 &&
              selectedPayment < paymentMethods.length
          ? selectedPayment
          : 0];

  /// Converts to JSON.
  Map<String, Object?> toJson() => {
    'amountMillions': amountMillions,
    'pricePerMillion': pricePerMillion,
    'vatPercent': vatPercent,
    'qunaPerPack': qunaPerPack,
    'packPrice': packPrice,
    'qunaPerChest': qunaPerChest,
    'millionsPerChest': millionsPerChest,
    'paymentMethods': [for (final m in paymentMethods) m.toJson()],
    'selectedPayment': selectedPayment,
    'sellers': [for (final s in sellers) s.toJson()],
    'currency': currency,
    'targetCurrency': targetCurrency,
    'ratesPerEur': {
      for (final e in ratesPerEur.entries) e.key: e.value.toString(),
    },
    'rateSource': rateSource.name,
    'rateDate': rateDate,
  };
}

/// A named copy of the calculator settings (requirement FR-17).
@immutable
class Profile {
  /// Creates a profile.
  const Profile({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.settings,
  });

  /// Unique id, stable across devices.
  final String id;

  /// User-chosen name, unique ignoring case.
  final String name;

  /// When the profile was last saved.
  final DateTime updatedAt;

  /// The saved calculator settings.
  final CalculatorSettings settings;
}

/// One seller's all-in price in a snapshot.
@immutable
class SnapshotPrice {
  /// Creates a snapshot price.
  const SnapshotPrice({required this.name, required this.eurPerMillion});

  /// Reads a snapshot price from [json].
  factory SnapshotPrice.fromJson(Map<String, Object?> json) => SnapshotPrice(
    name: json['name']! as String,
    eurPerMillion: Decimal.parse(json['eurPerMillion']! as String),
  );

  /// Seller name at capture time.
  final String name;

  /// All-in price per 1M Kina, in EUR.
  final Decimal eurPerMillion;

  /// Converts to JSON.
  Map<String, Object?> toJson() => {
    'name': name,
    'eurPerMillion': eurPerMillion.toString(),
  };
}

/// A manually saved price snapshot (requirement FR-18).
@immutable
class PriceSnapshot {
  /// Creates a snapshot.
  const PriceSnapshot({
    required this.id,
    required this.takenAt,
    required this.currency,
    required this.eurRate,
    required this.rateSource,
    required this.millions,
    required this.sellers,
    this.rateDate,
    this.officialEurPerMillion,
  });

  /// Unique id.
  final String id;

  /// Capture time.
  final DateTime takenAt;

  /// Calculator currency at capture.
  final String currency;

  /// Units of [currency] per 1 EUR at capture.
  final Decimal eurRate;

  /// Rate source label at capture.
  final String rateSource;

  /// Rate publication date at capture, if any.
  final String? rateDate;

  /// Kina amount in millions at capture.
  final Decimal millions;

  /// All-in price per seller, in EUR per 1M.
  final List<SnapshotPrice> sellers;

  /// Official Quna price in EUR per 1M, when the Quna setup was valid.
  final Decimal? officialEurPerMillion;
}

/// A saved marketplace item valuation (requirement FR-14).
@immutable
class JournalEntry {
  /// Creates a journal entry.
  const JournalEntry({
    required this.id,
    required this.date,
    required this.item,
    required this.kina,
    required this.qunaEquivalent,
    required this.officialEur,
    required this.rmtEur,
    required this.currency,
    required this.fxRatePerEur,
  });

  /// Unique id.
  final String id;

  /// When the item was saved.
  final DateTime date;

  /// Item name, at most 80 characters.
  final String item;

  /// Item price in raw Kina.
  final Decimal kina;

  /// Proportional Quna value.
  final Decimal qunaEquivalent;

  /// Official money value, in EUR.
  final Decimal officialEur;

  /// RMT money value, in EUR.
  final Decimal rmtEur;

  /// Calculator currency at capture.
  final String currency;

  /// Units of [currency] per 1 EUR at capture.
  final Decimal fxRatePerEur;
}
