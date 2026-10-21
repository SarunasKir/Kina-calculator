import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/analysis/analysis_logic.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_data/kina_data.dart';

Decimal d(String s) => Decimal.parse(s);

PriceSnapshot snap(int minute, List<String> prices, {String? official}) =>
    PriceSnapshot(
      id: '$minute',
      takenAt: DateTime.utc(2026, 10, 1, 0, minute),
      currency: 'EUR',
      eurRate: Decimal.one,
      rateSource: 'Saved rates',
      millions: d('300'),
      sellers: [
        for (var i = 0; i < prices.length; i++)
          SnapshotPrice(name: 'S$i', eurPerMillion: d(prices[i])),
      ],
      officialEurPerMillion: official == null ? null : d(official),
    );

void main() {
  final defaults = CalculatorSettings.defaults;

  group('breakdown', () {
    test('explains each step', () {
      final lines = breakdown(CalculatorView.from(defaults));
      String value(String label) =>
          lines.firstWhere((l) => l.label == label).value;
      expect(value('Quantity'), '300 million Kina × € 1.00 per 1M');
      expect(value('Seller subtotal'), startsWith('€ 300.00'));
      expect(value('VAT'), '€ 70.37 (23.4567% of the seller subtotal)');
      expect(
        value('Payment fee'),
        '€ 15.43 (3.9% of subtotal + VAT, plus € 0.99 fixed)',
      );
      expect(value('RMT total'), '€ 385.80 all-in');
      expect(value('Quna needed'), '90000 Quna');
      expect(
        value('Official cost'),
        '€ 1147.50 (90000 Quna ÷ 4000 per pack × € 51.00)',
      );
      expect(value('Savings'), startsWith('You save € 761.70'));
      expect(
        value('Seller B'),
        '€ 450.00 + € 105.56 VAT + € 22.66 fee = € 578.22',
      );
    });

    test('flags invalid Quna inputs', () {
      final lines = breakdown(
        CalculatorView.from(defaults.copyWith(qunaPerChest: '0')),
      );
      expect(lines.map((l) => l.label), isNot(contains('Quna needed')));
      expect(
        lines.firstWhere((l) => l.label == 'Official cost').value,
        'Invalid Quna conversion inputs',
      );
    });
  });

  group('snapshotOf', () {
    final at = DateTime.utc(2026, 10, 21);

    test('captures all-in EUR per 1M for each seller and official', () {
      final s = snapshotOf(
        CalculatorView.from(defaults),
        id: 'id',
        takenAt: at,
      );
      expect(s.id, 'id');
      expect(s.takenAt, at);
      expect(s.millions, d('300'));
      expect(s.rateSource, startsWith('Saved rates'));
      expect(s.sellers.map((p) => p.name), [
        'Seller A',
        'Seller B',
        'Seller C',
      ]);
      expect(s.sellers.map((p) => p.eurPerMillion), [
        d('1.286'),
        d('1.9274'),
        d('2.5687'),
      ]);
      expect(s.officialEurPerMillion, d('3.825'));
    });

    test('converts other currencies to EUR', () {
      final s = snapshotOf(
        CalculatorView.from(defaults.copyWith(currency: 'USD')),
        id: 'id',
        takenAt: at,
      );
      expect(s.currency, 'USD');
      expect(s.eurRate, d('1.10'));
      expect(s.sellers.first.eurPerMillion, d('1.1691'));
    });

    test('has no official price when the Quna setup is invalid', () {
      final s = snapshotOf(
        CalculatorView.from(defaults.copyWith(packPrice: '0')),
        id: 'id',
        takenAt: at,
      );
      expect(s.officialEurPerMillion, isNull);
    });

    test('needs a positive amount and rate', () {
      expect(
        () => snapshotOf(
          CalculatorView.from(defaults.copyWith(amountMillions: '0')),
          id: 'id',
          takenAt: at,
        ),
        throwsA(
          isA<SnapshotException>().having(
            (e) => e.toString(),
            'message',
            startsWith('Enter a positive Kina amount'),
          ),
        ),
      );
      expect(
        () => snapshotOf(
          CalculatorView.from(
            defaults.copyWith(ratesPerEur: {'EUR': Decimal.zero}),
          ),
          id: 'id',
          takenAt: at,
        ),
        throwsA(isA<SnapshotException>()),
      );
    });
  });

  group('history series', () {
    test('are named after the newest snapshot, plus official', () {
      final series = seriesOf([
        snap(0, ['1']),
        snap(1, ['1', '2']),
      ]);
      expect(series.map((s) => s.label), ['S0', 'S1', 'Official Quna']);
      expect(seriesOf(const []).map((s) => s.label), ['Official Quna']);
    });

    test('compare by position', () {
      expect(
        const HistorySeries.seller(1, 'A'),
        const HistorySeries.seller(1, 'B'),
      );
      expect(
        const HistorySeries.seller(1, 'A').hashCode,
        const HistorySeries.seller(1, 'B').hashCode,
      );
      expect(
        const HistorySeries.official(),
        isNot(const HistorySeries.seller(0, 'A')),
      );
    });

    test('points skip missing and zero values', () {
      final snapshots = [
        snap(0, ['1.2'], official: '3.8'),
        snap(1, ['0']),
        snap(2, ['1.1', '1.6']),
      ];
      expect(
        pointsOf(
          snapshots,
          const HistorySeries.seller(0, 'S0'),
        ).map((p) => p.value),
        [d('1.2'), d('1.1')],
      );
      expect(
        pointsOf(snapshots, const HistorySeries.seller(1, 'S1')).single.at,
        DateTime.utc(2026, 10, 1, 0, 2),
      );
      expect(
        pointsOf(snapshots, const HistorySeries.official()).single.value,
        d('3.8'),
      );
    });

    test('points cover only the newest $chartWindow snapshots', () {
      final snapshots = [
        for (var i = 0; i < chartWindow + 5; i++) snap(i, ['1']),
      ];
      final points = pointsOf(snapshots, const HistorySeries.seller(0, 'S0'));
      expect(points, hasLength(chartWindow));
      expect(points.first.at, DateTime.utc(2026, 10, 1, 0, 5));
    });
  });
}
