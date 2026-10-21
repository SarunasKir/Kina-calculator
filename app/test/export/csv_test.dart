import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_app/src/export/csv.dart';
import 'package:kina_data/kina_data.dart';

Decimal d(String s) => Decimal.parse(s);

List<String> lines(String csv) => csv.split('\r\n')..removeLast();

void main() {
  test('toCsv quotes only fields that need it', () {
    expect(
      toCsv([
        ['plain', 'a,b', 'say "hi"', 'two\nlines'],
      ]),
      'plain,"a,b","say ""hi""","two\nlines"\r\n',
    );
  });

  test('csvFileName stamps the date and time', () {
    expect(
      csvFileName('kina_journal', DateTime(2026, 10, 21, 9, 5)),
      'kina_journal_20261021_0905.csv',
    );
  });

  group('calculatorCsv', () {
    test('lists the metrics and each seller', () {
      final rows = lines(
        calculatorCsv(CalculatorView.from(CalculatorSettings.defaults)),
      );
      expect(rows.first, 'Metric,Value');
      expect(rows, contains('Kina (millions),300'));
      expect(rows, contains('Payment method,Visa / Mastercard'));
      expect(rows, contains('RMT total,385.80'));
      expect(rows, contains('Quna required,90000'));
      expect(rows, contains('Official equivalent,1147.50'));
      expect(rows, contains('Savings,761.70'));
      expect(rows, contains('1 EUR in calculator currency,1'));
      expect(rows.last, startsWith('Seller C,Total € 770.62'));
    });

    test('leaves out the official rows when the Quna setup is invalid', () {
      final csv = calculatorCsv(
        CalculatorView.from(
          CalculatorSettings.defaults.copyWith(qunaPerPack: '0'),
        ),
      );
      expect(csv, isNot(contains('Quna required')));
      expect(csv, contains('Official Quna price unavailable'));
    });
  });

  test('journalCsv writes entries oldest first', () {
    JournalEntry entry(String id, int day, String item) => JournalEntry(
      id: id,
      date: DateTime.utc(2026, 10, day),
      item: item,
      kina: d('25000000'),
      qunaEquivalent: d('7500'),
      officialEur: d('95.625'),
      rmtEur: d('33.05'),
      currency: 'USD',
      fxRatePerEur: d('1.1'),
    );
    final rows = lines(
      journalCsv([entry('b', 2, 'Sword, big'), entry('a', 1, 'Shield')]),
    );
    expect(rows, hasLength(3));
    expect(rows[0], startsWith('Timestamp,Item,Kina price'));
    expect(
      rows[1],
      '2026-10-01T00:00:00.000Z,Shield,25000000,7500.00,95.63,33.05,USD,1.1',
    );
    expect(rows[2], contains('"Sword, big"'));
  });

  test('snapshotsCsv pads sellers and blanks a missing official price', () {
    PriceSnapshot snap(List<String> names, {Decimal? official}) =>
        PriceSnapshot(
          id: names.join(),
          takenAt: DateTime.utc(2026, 10, names.length),
          currency: 'EUR',
          eurRate: Decimal.one,
          rateSource: 'Saved rates',
          millions: d('300'),
          sellers: [
            for (final n in names)
              SnapshotPrice(name: n, eurPerMillion: d('1.286')),
          ],
          officialEurPerMillion: official,
          rateDate: names.length == 2 ? '2026-10-20' : null,
        );
    final rows = lines(
      snapshotsCsv([
        snap(['A'], official: d('3.825')),
        snap(['A', 'B']),
      ]),
    );
    expect(rows[0].split(','), [
      'Date and time',
      'Original currency',
      'Rate (1 EUR)',
      'Kina (millions)',
      'Seller 1 name',
      'Seller 1 EUR per 1M',
      'Seller 2 name',
      'Seller 2 EUR per 1M',
      'Official Quna EUR per 1M',
      'FX source',
      'FX publication date',
    ]);
    expect(
      rows[1],
      '2026-10-01T00:00:00.000Z,EUR,1,300,A,1.2860,,,3.8250,Saved rates,',
    );
    expect(rows[2].split(',').skip(4), [
      'A',
      '1.2860',
      'B',
      '1.2860',
      '',
      'Saved rates',
      '2026-10-20',
    ]);
  });
}
