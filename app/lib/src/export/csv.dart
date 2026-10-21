import 'package:intl/intl.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_data/kina_data.dart';

/// Writes [rows] as CSV (RFC 4180): fields with commas, quotes or line breaks
/// are quoted, and rows end with CRLF.
String toCsv(List<List<String>> rows) {
  String field(String value) => value.contains(RegExp('[",\r\n]'))
      ? '"${value.replaceAll('"', '""')}"'
      : value;
  return rows.map((row) => '${row.map(field).join(',')}\r\n').join();
}

/// A file name with a timestamp, such as `kina_journal_20261021_1015.csv`.
String csvFileName(String stem, DateTime now) =>
    '${stem}_${DateFormat('yyyyMMdd_HHmm').format(now)}.csv';

/// The current calculation as CSV (requirement FR-8).
String calculatorCsv(CalculatorView view) {
  final s = view.settings;
  final r = view.main;
  return toCsv([
    ['Metric', 'Value'],
    ['Kina (millions)', s.amountMillions],
    ['Currency', s.currency],
    ['FX rate source', rateStatus(s)],
    ['FX published', s.rateDate ?? ''],
    ['1 EUR in calculator currency', s.ratesPerEur[s.currency].toString()],
    ['RMT per 1M', s.pricePerMillion],
    ['Payment method', s.payment.name],
    ['Seller subtotal', r.rmt.subtotal.toStringAsFixed(2)],
    ['VAT', r.rmt.vat.toStringAsFixed(2)],
    ['Payment fee', r.rmt.fee.toStringAsFixed(2)],
    ['Payment fee percentage', s.payment.feePercent],
    ['Payment fixed fee', s.payment.fixedFee],
    ['RMT total', r.rmt.total.toStringAsFixed(2)],
    if (r.officialValid) ...[
      ['Quna required', r.qunaRequired.toStringAsFixed(0)],
      ['Official equivalent', r.officialCost.toStringAsFixed(2)],
      ['Savings', r.savings.toStringAsFixed(2)],
    ],
    for (final o in view.sellers) [o.seller.name, view.sellerLine(o)],
  ]);
}

/// The purchase journal as CSV, oldest first (requirement FR-15).
String journalCsv(List<JournalEntry> entries) => toCsv([
  [
    'Timestamp',
    'Item',
    'Kina price',
    'Quna equivalent',
    'Official EUR estimate',
    'RMT EUR estimate',
    'Calculator currency at capture',
    'FX units per EUR at capture',
  ],
  for (final e in entries.reversed)
    [
      e.date.toIso8601String(),
      e.item,
      e.kina.toStringAsFixed(0),
      e.qunaEquivalent.toStringAsFixed(2),
      e.officialEur.toStringAsFixed(2),
      e.rmtEur.toStringAsFixed(2),
      e.currency,
      e.fxRatePerEur.toString(),
    ],
]);

/// Price snapshots as CSV, oldest first (requirement FR-19).
String snapshotsCsv(List<PriceSnapshot> snapshots) {
  final sellerCount = snapshots.fold(
    0,
    (most, s) => s.sellers.length > most ? s.sellers.length : most,
  );
  return toCsv([
    [
      'Date and time',
      'Original currency',
      'Rate (1 EUR)',
      'Kina (millions)',
      for (var i = 1; i <= sellerCount; i++) ...[
        'Seller $i name',
        'Seller $i EUR per 1M',
      ],
      'Official Quna EUR per 1M',
      'FX source',
      'FX publication date',
    ],
    for (final s in snapshots)
      [
        s.takenAt.toIso8601String(),
        s.currency,
        s.eurRate.toString(),
        s.millions.toString(),
        for (var i = 0; i < sellerCount; i++) ...[
          if (i < s.sellers.length) ...[
            s.sellers[i].name,
            s.sellers[i].eurPerMillion.toStringAsFixed(4),
          ] else ...[
            '',
            '',
          ],
        ],
        s.officialEurPerMillion?.toStringAsFixed(4) ?? '',
        s.rateSource,
        s.rateDate ?? '',
      ],
  ]);
}
