import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:kina_data/src/database.dart';
import 'package:kina_data/src/models.dart';
import 'package:kina_data/src/repositories/journal_repository.dart';
import 'package:kina_data/src/repositories/profile_repository.dart';
import 'package:kina_data/src/repositories/settings_repository.dart';
import 'package:kina_data/src/repositories/snapshot_repository.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// The v55 currency order: settings store currencies by index.
const v55Currencies = ['EUR', 'USD', 'GBP', 'CAD', 'AUD'];

/// The v55 payment method order.
const v55PaymentMethods = [
  'Visa / Mastercard',
  'Google Pay',
  'Klarna',
  'PayPal',
  'iDEAL',
  'Skrill',
  'Crypto',
  'Other',
];

// Namespace for deterministic ids, so importing the same file twice updates
// records instead of duplicating them.
const _namespace = '6c1f8a5e-2b7d-4c39-9f0e-5a4d3b2c1e0f';
const _uuid = Uuid();

String _stableId(String kind, Object? record) =>
    _uuid.v5(_namespace, '$kind:${jsonEncode(record)}');

Decimal _decimal(Object? value) => switch (value) {
  final int v => Decimal.fromInt(v),
  final double v when v.isFinite => Decimal.parse(v.toString()),
  final String v => Decimal.tryParse(v) ?? Decimal.zero,
  _ => Decimal.zero,
};

String _string(Object? value, String fallback) =>
    value is String ? value : fallback;

List<Object?> _list(Object? value) => value is List<Object?> ? value : const [];

String _currency(Object? index, String fallback) =>
    index is int && index >= 0 && index < v55Currencies.length
    ? v55Currencies[index]
    : fallback;

/// Converts a decoded v55 `settings.json` (or a profile's `Data`) to
/// [CalculatorSettings]. Missing or broken fields fall back to defaults.
CalculatorSettings settingsFromV55(Map<String, Object?> json) {
  final d = CalculatorSettings.defaults;
  final feePercent = _list(json['FeePercent']);
  final feeFixed = _list(json['FeeFixed']);
  final methods = [
    for (var i = 0; i < v55PaymentMethods.length; i++)
      PaymentMethod(
        name: v55PaymentMethods[i],
        feePercent:
            i < feePercent.length &&
                feePercent[i] is String &&
                (feePercent[i]! as String).isNotEmpty
            ? feePercent[i]! as String
            : d.paymentMethods[i].feePercent,
        fixedFee:
            i < feeFixed.length &&
                feeFixed[i] is String &&
                (feeFixed[i]! as String).isNotEmpty
            ? feeFixed[i]! as String
            : d.paymentMethods[i].fixedFee,
      ),
  ];
  final names = _list(json['SellerNames']);
  final prices = _list(json['SellerPrices']);
  final sellers = [
    for (var i = 0; i < d.sellers.length; i++)
      Seller(
        name: _string(i < names.length ? names[i] : null, d.sellers[i].name),
        pricePerMillion: _string(
          i < prices.length ? prices[i] : null,
          d.sellers[i].pricePerMillion,
        ),
      ),
  ];
  final fx = _list(json['FX']);
  final rates =
      fx.length == v55Currencies.length &&
          fx.skip(1).every((v) => _decimal(v) > Decimal.zero)
      ? {
          for (var i = 0; i < v55Currencies.length; i++)
            v55Currencies[i]: i == 0 ? Decimal.one : _decimal(fx[i]),
        }
      : d.ratesPerEur;
  final payment = json['Payment'];
  final syncDate = _string(json['SyncDate'], '');
  return CalculatorSettings(
    amountMillions: _string(json['Amount'], d.amountMillions),
    pricePerMillion: _string(json['Price'], d.pricePerMillion),
    vatPercent: _string(json['Vat'], d.vatPercent),
    qunaPerPack: _string(json['QunaPack'], d.qunaPerPack),
    packPrice: _string(json['PackEuro'], d.packPrice),
    qunaPerChest: _string(json['TradeQuna'], d.qunaPerChest),
    millionsPerChest: _string(json['TradeKina'], d.millionsPerChest),
    paymentMethods: methods,
    selectedPayment: payment is int && payment >= 0 && payment < methods.length
        ? payment
        : 0,
    sellers: sellers,
    currency: _currency(json['Currency'], 'EUR'),
    targetCurrency: _currency(json['FXTarget'], 'USD'),
    ratesPerEur: rates,
    rateSource: switch (json['RateMode']) {
      'ECB via Frankfurter' => RateSource.ecb,
      'Manual override' => RateSource.manual,
      _ => RateSource.saved,
    },
    rateDate: syncDate.isEmpty ? null : syncDate,
  );
}

/// Converts one decoded v55 `price_history.json` entry.
PriceSnapshot snapshotFromV55(Map<String, Object?> json) {
  final names = _list(json['names']);
  final prices = _list(json['all_in_eur']);
  final official = prices.length > names.length
      ? _decimal(prices[names.length])
      : Decimal.zero;
  final rateDate = _string(json['fx_date'], '');
  return PriceSnapshot(
    id: _stableId('snapshot', json),
    takenAt: DateTime.parse(json['timestamp']! as String),
    currency: _string(json['currency'], 'EUR'),
    eurRate: _decimal(json['eur_rate']),
    rateSource: _string(json['fx_source'], ''),
    rateDate: rateDate.isEmpty ? null : rateDate,
    millions: _decimal(json['millions']),
    sellers: [
      for (var i = 0; i < names.length; i++)
        SnapshotPrice(
          name: _string(names[i], 'Seller ${i + 1}'),
          eurPerMillion: i < prices.length ? _decimal(prices[i]) : Decimal.zero,
        ),
    ],
    officialEurPerMillion: official > Decimal.zero ? official : null,
  );
}

/// Converts one decoded v55 `marketplace_purchases.json` entry.
JournalEntry journalEntryFromV55(Map<String, Object?> json) => JournalEntry(
  id: _stableId('journal', json),
  date: DateTime.parse(json['date']! as String),
  item: _string(json['item'], ''),
  kina: _decimal(json['kina']),
  qunaEquivalent: _decimal(json['quna_equivalent']),
  officialEur: _decimal(json['official_eur']),
  rmtEur: _decimal(json['rmt_eur']),
  currency: _string(json['currency'], 'EUR'),
  fxRatePerEur: _decimal(json['fx_rate_per_eur']),
);

/// How many records an import brought in.
@immutable
class ImportSummary {
  /// Creates a summary.
  const ImportSummary({
    required this.settings,
    required this.profiles,
    required this.snapshots,
    required this.journalEntries,
  });

  /// Whether settings were imported.
  final bool settings;

  /// Profiles imported.
  final int profiles;

  /// Snapshots imported.
  final int snapshots;

  /// Journal entries imported.
  final int journalEntries;
}

/// Imports the contents of v55 data files into [db] (requirement DATA-1).
///
/// Pass the raw text of whichever files the user picked; null skips a file.
/// Importing the same history or journal twice does not create duplicates.
/// Throws [FormatException] if a file is not valid JSON.
Future<ImportSummary> importV55(
  KinaDatabase db, {
  String? settingsJson,
  String? profilesJson,
  String? historyJson,
  String? journalJson,
}) => db.transaction(() async {
  if (settingsJson != null) {
    await SettingsRepository(
      db,
    ).save(settingsFromV55(jsonDecode(settingsJson) as Map<String, Object?>));
  }

  var profiles = 0;
  if (profilesJson != null) {
    final repo = ProfileRepository(db);
    for (final p in _list(jsonDecode(profilesJson))) {
      final json = p! as Map<String, Object?>;
      final data = json['Data'];
      await repo.save(
        _string(json['Name'], 'Imported profile'),
        settingsFromV55(
          data is Map<String, Object?> ? data : const <String, Object?>{},
        ),
      );
      profiles++;
    }
  }

  var snapshots = 0;
  if (historyJson != null) {
    final repo = SnapshotRepository(db);
    for (final s in _list(jsonDecode(historyJson))) {
      await repo.add(snapshotFromV55(s! as Map<String, Object?>));
      snapshots++;
    }
  }

  var entries = 0;
  if (journalJson != null) {
    final repo = JournalRepository(db);
    for (final e in _list(jsonDecode(journalJson))) {
      await repo.add(journalEntryFromV55(e! as Map<String, Object?>));
      entries++;
    }
  }

  return ImportSummary(
    settings: settingsJson != null,
    profiles: profiles,
    snapshots: snapshots,
    journalEntries: entries,
  );
});
