/// Alternate route suggestion — surfaces when bottleneck_score > 0.75.
///
/// Suggests an alternative zone/route to avoid congestion.
library;

import 'package:flutter/material.dart';

import '../../accessibility/wcag_tokens.dart';

class AlternateRouteSuggestion extends StatelessWidget {
  const AlternateRouteSuggestion({
    super.key,
    required this.fromZoneId,
    required this.suggestedZoneId,
    required this.bottleneckScore,
  });

  final String fromZoneId;
  final double bottleneckScore;
  final String suggestedZoneId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityPercent = (bottleneckScore * 100).round();

    return Semantics(
      label: '$fromZoneId is $severityPercent% congested. '
          'Alternate route via $suggestedZoneId available.',
      child: Row(
        children: [
          const Icon(
            Icons.alt_route_rounded,
            color: AvenuColors.crowdCritical,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Route congested ($severityPercent%)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AvenuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Try via $suggestedZoneId instead',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AvenuColors.accentGreen,
                  ),
                ),
              ],
            ),
          ),
          // Navigate button — 44x44 minimum
          SizedBox(
            width: AvenuTouchTargets.minimum,
            height: AvenuTouchTargets.minimum,
            child: IconButton(
              onPressed: () {
                // TODO: trigger wayfinding provider with suggestedZoneId
              },
              icon: const Icon(
                Icons.navigation_rounded,
                color: AvenuColors.accentBlue,
              ),
              tooltip: 'Navigate to alternate route',
            ),
          ),
        ],
      ),
    );
  }
}
