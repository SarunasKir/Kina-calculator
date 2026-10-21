import 'package:decimal/decimal.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_core/kina_core.dart';
import 'package:kina_data/kina_data.dart';
import 'package:meta/meta.dart';

/// One line of the price breakdown.
typedef BreakdownLine = ({String label, String value});

/// Explains each step of the calculation (requirement FR-16).
List<BreakdownLine> breakdown(CalculatorView view) {
  final s = view.settings;
  final r = view.main;
  final money = view.money;
  return [
    (
      label: 'Quantity',
      value:
          '${parseAmount(s.amountMillions)} million Kina × '
          '${money(parseAmount(s.pricePerMillion))} per 1M',
    ),
    (
      label: 'Seller subtotal',
      value: '${money(r.rmt.subtotal)} (quantity × seller price)',
    ),
    (
      label: 'VAT',
      value:
          '${money(r.rmt.vat)} '
          '(${parseAmount(s.vatPercent)}% of the seller subtotal)',
    ),
    (
      label: 'Payment fee',
      value:
          '${money(r.rmt.fee)} (${parseAmount(s.payment.feePercent)}% of '
          'subtotal + VAT, plus ${money(parseAmount(s.payment.fixedFee))} '
          'fixed)',
    ),
    (label: 'RMT total', value: '${money(r.rmt.total)} all-in'),
    if (r.officialValid) ...[
      (label: 'Quna needed', value: formatQuna(r.qunaRequired)),
      (
        label: 'Official cost',
        value:
            '${money(r.officialCost)} (${formatQuna(r.qunaRequired)} ÷ '
            '${parseAmount(s.qunaPerPack)} per pack × '
            '${money(parseAmount(s.packPrice))})',
      ),
      (label: 'Savings', value: view.savingsLine),
    ] else
      (label: 'Official cost', value: 'Invalid Quna conversion inputs'),
    for (final o in view.sellers)
      (
        label: o.seller.name,
        value:
            '${money(o.result.rmt.subtotal)} + ${money(o.result.rmt.vat)} '
            'VAT + ${money(o.result.rmt.fee)} fee = '
            '${money(o.result.rmt.total)}',
      ),
  ];
}

/// Why a snapshot cannot be taken.
class SnapshotException implements Exception {
  /// Creates the exception.
  const SnapshotException(this.message);

  /// A user-facing reason.
  final String message;

  @override
  String toString() => message;
}

Decimal _perMillionEur(Decimal total, Decimal millions, Decimal rate) =>
    toScale(total.toRational() / (millions * rate).toRational(), 4);

/// Captures each seller's and the official all-in price, in EUR per 1M Kina
/// (requirement FR-18). Throws [SnapshotException] when the Kina amount or
/// the exchange rate is not positive.
PriceSnapshot snapshotOf(
  CalculatorView view, {
  required String id,
  required DateTime takenAt,
}) {
  final s = view.settings;
  final millions = parseAmount(s.amountMillions);
  if (millions <= Decimal.zero) {
    throw const SnapshotException(
      'Enter a positive Kina amount before saving a snapshot',
    );
  }
  final rate = s.ratesPerEur[s.currency];
  if (rate == null || rate <= Decimal.zero) {
    throw const SnapshotException('The currency exchange rate is invalid');
  }
  return PriceSnapshot(
    id: id,
    takenAt: takenAt,
    currency: s.currency,
    eurRate: rate,
    rateSource: rateStatus(s),
    rateDate: s.rateDate,
    millions: millions,
    sellers: [
      for (final o in view.sellers)
        SnapshotPrice(
          name: o.seller.name,
          eurPerMillion: _perMillionEur(o.result.rmt.total, millions, rate),
        ),
    ],
    officialEurPerMillion: view.main.officialValid
        ? _perMillionEur(view.main.officialCost, millions, rate)
        : null,
  );
}

/// How many recent snapshots the chart shows.
const chartWindow = 120;

/// A series the history chart can show: a seller position or the official
/// price.
@immutable
class HistorySeries {
  /// The seller at [index].
  const HistorySeries.seller(this.index, this.label);

  /// The official Quna price.
  const HistorySeries.official() : index = null, label = 'Official Quna';

  /// Seller position, or null for official.
  final int? index;

  /// Display name.
  final String label;

  /// This series' price in [snapshot], if it has one above zero.
  Decimal? valueIn(PriceSnapshot snapshot) {
    final i = index;
    final value = i == null
        ? snapshot.officialEurPerMillion
        : i < snapshot.sellers.length
        ? snapshot.sellers[i].eurPerMillion
        : null;
    return value != null && value > Decimal.zero ? value : null;
  }

  @override
  bool operator ==(Object other) =>
      other is HistorySeries && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

/// The series to offer, named after the newest snapshot's sellers.
List<HistorySeries> seriesOf(List<PriceSnapshot> snapshots) => [
  if (snapshots.isNotEmpty)
    for (var i = 0; i < snapshots.last.sellers.length; i++)
      HistorySeries.seller(i, snapshots.last.sellers[i].name),
  const HistorySeries.official(),
];

/// One chart point: when, and the price in EUR per 1M.
typedef HistoryPoint = ({DateTime at, Decimal value});

/// The points of [series] over the newest [chartWindow] snapshots, oldest
/// first. Snapshots without a value for the series are left out.
List<HistoryPoint> pointsOf(
  List<PriceSnapshot> snapshots,
  HistorySeries series,
) {
  final recent = snapshots.length > chartWindow
      ? snapshots.sublist(snapshots.length - chartWindow)
      : snapshots;
  return [
    for (final s in recent)
      if (series.valueIn(s) case final value?) (at: s.takenAt, value: value),
  ];
}
