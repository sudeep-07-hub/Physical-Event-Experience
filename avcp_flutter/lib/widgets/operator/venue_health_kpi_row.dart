/// Venue health KPI row — summary cards for operator overview.
///
/// Shows: total crowd count, average wait time, active alerts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessibility/wcag_tokens.dart';
import '../../providers/crowd_state_provider.dart';

class VenueHealthKpiRow extends ConsumerWidget {
  const VenueHealthKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allZonesAsync = ref.watch(allZonesStreamProvider);
    final alertsAsync = ref.watch(alertsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: allZonesAsync.when(
        data: (vectors) {
          final totalDensity = vectors.fold<double>(
            0.0,
            (sum, v) => sum + v.densityPpm2,
          );
          final avgDwell = vectors.isEmpty
              ? 0.0
              : vectors.fold<double>(0, (s, v) => s + v.dwellRatio) /
                  vectors.length;
          final alertCount = alertsAsync.valueOrNull?.length ?? 0;

          return Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.people_outline,
                  label: 'Zone Density',
                  value: '${totalDensity.toStringAsFixed(1)} p/m²',
                  color: AvenuColors.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  icon: Icons.hourglass_empty,
                  label: 'Avg Dwell',
                  value: '${(avgDwell * 100).round()}%',
                  color: AvenuColors.crowdModerate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Alerts',
                  value: '$alertCount',
                  color: alertCount > 0
                      ? AvenuColors.crowdCritical
                      : AvenuColors.accentGreen,
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AvenuColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AvenuColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
