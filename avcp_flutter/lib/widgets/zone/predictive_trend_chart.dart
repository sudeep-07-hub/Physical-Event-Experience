/// Predictive trend chart — 5-minute sparkline using fl_chart.
///
/// Shows current density, T+60s prediction, and T+300s prediction
/// as a compact sparkline chart.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../accessibility/wcag_tokens.dart';

class PredictiveTrendChart extends StatelessWidget {
  const PredictiveTrendChart({
    super.key,
    required this.currentDensity,
    required this.predicted60s,
    required this.predicted300s,
  });

  final double currentDensity;
  final double predicted60s;
  final double predicted300s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendUp = predicted300s > currentDensity * 1.1;
    final trendColor =
        trendUp ? AvenuColors.crowdCritical : AvenuColors.accentGreen;

    return Semantics(
      label: 'Density trend: current ${currentDensity.toStringAsFixed(1)}, '
          'predicted ${predicted300s.toStringAsFixed(1)} in 5 minutes. '
          '${trendUp ? "Increasing" : "Stable or decreasing"}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trendUp ? Icons.trending_up : Icons.trending_down,
                color: trendColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Density trend (next 5 min)',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AvenuColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Now', '1m', '5m'];
                        if (value.toInt() >= 0 &&
                            value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              labels[value.toInt()],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AvenuColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 2,
                minY: 0,
                maxY: 6.5, // Fruin crush limit
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, currentDensity),
                      FlSpot(1, predicted60s),
                      FlSpot(2, predicted300s),
                    ],
                    isCurved: true,
                    color: trendColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: trendColor,
                          strokeWidth: 2,
                          strokeColor: AvenuColors.surfaceElevated,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: trendColor.withValues(alpha: 0.1),
                    ),
                  ),
                  // Danger zone line at LoS-E threshold
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 4.0),
                      FlSpot(2, 4.0),
                    ],
                    isCurved: false,
                    color: AvenuColors.crowdCritical.withValues(alpha: 0.3),
                    barWidth: 1,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
