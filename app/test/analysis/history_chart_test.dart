import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/analysis/history_chart.dart';

void main() {
  test('niceStep rounds up to 1, 2 or 5 times a power of ten', () {
    expect(niceStep(0.03), closeTo(0.05, 1e-12));
    expect(niceStep(0.07), closeTo(0.1, 1e-12));
    expect(niceStep(0.15), closeTo(0.2, 1e-12));
    expect(niceStep(1), closeTo(1, 1e-12));
    expect(niceStep(3), closeTo(5, 1e-12));
  });

  group('chartRange', () {
    test('defaults to 0 to 1 without values', () {
      expect(chartRange(const []), (min: 0, max: 1, step: 0.25));
    });

    test('pads and snaps to round steps', () {
      final r = chartRange([1.14, 1.35]);
      expect(r.step, closeTo(0.1, 1e-12));
      expect(r.min, closeTo(1.1, 1e-9));
      expect(r.max, closeTo(1.4, 1e-9));
    });

    test('widens a flat line and never goes below zero', () {
      final r = chartRange([0.05, 0.05]);
      expect(r.min, 0);
      expect(r.max, greaterThan(0.05));
    });
  });

  Future<void> pump(WidgetTester tester, Widget chart) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 600, height: 300, child: chart)),
    ),
  );

  testWidgets('says when there is nothing to draw', (tester) async {
    await pump(tester, const HistoryChart(points: []));
    expect(find.text('No prices saved for this series yet'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('draws one point in the middle of an hour', (tester) async {
    final at = DateTime(2026, 10, 21, 12);
    await pump(
      tester,
      HistoryChart(points: [(at: at, value: Decimal.parse('1.2'))]),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.minX, at.millisecondsSinceEpoch - 1800000);
    expect(chart.data.maxX, at.millisecondsSinceEpoch + 1800000);
    expect(find.text('2026-10-21'), findsWidgets);
  });

  testWidgets('spaces points by elapsed time', (tester) async {
    final first = DateTime(2026, 10);
    final last = DateTime(2026, 10, 21);
    await pump(
      tester,
      HistoryChart(
        points: [
          (at: first, value: Decimal.parse('1.31')),
          (at: DateTime(2026, 10, 3), value: Decimal.parse('1.28')),
          (at: last, value: Decimal.parse('1.14')),
        ],
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.minX, first.millisecondsSinceEpoch);
    expect(chart.data.maxX, last.millisecondsSinceEpoch);
    expect(
      chart.data.lineBarsData.single.spots[1].x,
      DateTime(2026, 10, 3).millisecondsSinceEpoch,
    );
    expect(find.text('2026-10-01'), findsOneWidget);
    expect(find.text('2026-10-21'), findsOneWidget);
    expect(find.text('€ 1.20'), findsOneWidget);
  });
}
