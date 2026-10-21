import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kina_app/src/analysis/analysis_logic.dart';

/// A round step near [raw]: 1, 2 or 5 times a power of ten.
double niceStep(double raw) {
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final step = [1, 2, 5, 10].firstWhere((m) => m * magnitude >= raw);
  return step * magnitude;
}

/// The vertical range and grid step to show for [values]: padded so the line
/// does not touch the edges, widened when the prices barely move (as v55
/// does), and snapped to round steps so the axis labels line up.
({double min, double max, double step}) chartRange(List<double> values) {
  if (values.isEmpty) {
    return (min: 0, max: 1, step: 0.25);
  }
  final low = values.reduce(math.min);
  final high = values.reduce(math.max);
  var span = high - low;
  if (span < 0.02) {
    span = math.max(0.1, high * 0.06);
  }
  final pad = span * 0.16;
  final step = niceStep((span + 2 * pad) / 4);
  return (
    min: math.max(0, ((low - pad) / step).floor() * step),
    max: ((high + pad) / step).ceil() * step,
    step: step,
  );
}

/// A line of prices over time, spaced by real elapsed time (requirement
/// FR-19).
class HistoryChart extends StatelessWidget {
  /// Creates the chart.
  const HistoryChart({required this.points, super.key});

  /// Points oldest first.
  final List<HistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No prices saved for this series yet',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    final spots = [
      for (final p in points)
        FlSpot(p.at.millisecondsSinceEpoch.toDouble(), p.value.toDouble()),
    ];
    final range = chartRange([for (final s in spots) s.y]);
    final first = spots.first.x;
    final last = spots.last.x;
    // A single point sits in the middle of an hour-wide axis.
    final minX = first == last ? first - 1800000 : first;
    final maxX = first == last ? last + 1800000 : last;
    final dates = DateFormat('yyyy-MM-dd');
    final color = theme.colorScheme.primary;
    final grid = theme.colorScheme.outlineVariant;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: theme.textTheme.bodySmall),
    );

    // Right padding leaves room for the last date label.
    return Padding(
      padding: const EdgeInsets.only(right: 36),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: range.min,
          maxY: range.max,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: range.step,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: grid, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: grid),
              bottom: BorderSide(color: grid),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 64,
                interval: range.step,
                getTitlesWidget: (value, meta) => Text(
                  '€ ${value.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxX - minX,
                getTitlesWidget: (value, meta) =>
                    value == meta.min || value == meta.max
                    ? label(
                        dates.format(
                          DateTime.fromMillisecondsSinceEpoch(
                            (value == meta.min ? first : last).toInt(),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: color,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(radius: 3, color: color),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
