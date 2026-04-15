/// Wait time banner — surfaces when zone dwell_ratio > 0.6.
///
/// Shows the estimated wait time in minutes (not abstract scores)
/// with a visual indicator of the dwell ratio.
library;

import 'package:flutter/material.dart';

import '../../accessibility/wcag_tokens.dart';

class WaitTimeBanner extends StatelessWidget {
  const WaitTimeBanner({
    super.key,
    required this.zoneId,
    required this.dwellRatio,
    required this.estimatedWaitMinutes,
  });

  final String zoneId;
  final double dwellRatio;
  final int estimatedWaitMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$zoneId: estimated wait $estimatedWaitMinutes minutes. '
          '${(dwellRatio * 100).round()}% of visitors are stationary.',
      child: Row(
        children: [
          // Clock icon
          const Icon(
            Icons.hourglass_bottom_rounded,
            color: AvenuColors.crowdModerate,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Est. wait: $estimatedWaitMinutes min',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AvenuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Dwell ratio bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: dwellRatio,
                    backgroundColor: AvenuColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      dwellRatio > 0.8
                          ? AvenuColors.crowdCritical
                          : AvenuColors.crowdModerate,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
