/// Zone detail bottom sheet — swipe-up from map.
///
/// Displays: zone name, [CongestionIndicator], ETA in minutes,
/// 5-min sparkline via [PredictiveTrendChart], and [NavigateButton].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessibility/wcag_tokens.dart';
import '../../providers/crowd_state_provider.dart';
import 'congestion_indicator.dart';
import 'navigate_button.dart';
import 'predictive_trend_chart.dart';
import 'wait_time_estimate.dart';

class ZoneDetailSheet extends ConsumerWidget {
  const ZoneDetailSheet({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final crowdAsync = ref.watch(crowdStreamProvider(zoneId));
    final congestionAsync = ref.watch(congestionLevelProvider(zoneId));
    final waitTimeAsync = ref.watch(waitTimeProvider(zoneId));

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AvenuColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AvenuColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Zone name
              Semantics(
                header: true,
                child: Text(
                  _formatZoneName(zoneId),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AvenuColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Congestion indicator (color + icon + label)
              congestionAsync.when(
                data: (level) => CongestionIndicator(
                  level: level,
                  zoneName: _formatZoneName(zoneId),
                ),
                loading: () => const _ShimmerPlaceholder(),
                error: (_, __) => const Text('Unable to load congestion data'),
              ),
              const SizedBox(height: 16),

              // Wait time estimate (ETA in minutes)
              waitTimeAsync.when(
                data: (minutes) => WaitTimeEstimate(
                  estimatedMinutes: minutes,
                ),
                loading: () => const _ShimmerPlaceholder(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Predictive trend sparkline (next 5 min)
              crowdAsync.when(
                data: (vector) => PredictiveTrendChart(
                  currentDensity: vector.densityPpm2,
                  predicted60s: vector.predictedDensity60s,
                  predicted300s: vector.predictedDensity300s,
                ),
                loading: () => const _ShimmerPlaceholder(height: 120),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Navigate button
              NavigateButton(
                fromZoneId: zoneId,
                label: 'Navigate to this zone',
              ),
            ],
          ),
        );
      },
    );
  }

  /// Formats zone_id to human-readable name.
  /// "gate_c_concourse_level2" → "Gate C Concourse Level 2"
  String _formatZoneName(String zoneId) {
    return zoneId
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// Shimmer placeholder for loading states.
class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({this.height = 48});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AvenuColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
