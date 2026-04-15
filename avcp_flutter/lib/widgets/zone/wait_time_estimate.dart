/// Wait time estimate — shows ETA in minutes, not abstract scores.
library;

import 'package:flutter/material.dart';

import '../../accessibility/wcag_tokens.dart';

class WaitTimeEstimate extends StatelessWidget {
  const WaitTimeEstimate({
    super.key,
    required this.estimatedMinutes,
  });

  final int estimatedMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Estimated wait time: $estimatedMinutes minutes',
      child: Row(
        children: [
          Icon(
            _icon,
            color: _color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wait time',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AvenuColors.textSecondary,
                ),
              ),
              Text(
                '$estimatedMinutes min',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _color {
    if (estimatedMinutes <= 2) return AvenuColors.crowdFree;
    if (estimatedMinutes <= 5) return AvenuColors.crowdModerate;
    if (estimatedMinutes <= 10) return AvenuColors.crowdHigh;
    return AvenuColors.crowdCritical;
  }

  IconData get _icon {
    if (estimatedMinutes <= 2) return Icons.timer_outlined;
    if (estimatedMinutes <= 5) return Icons.timer;
    return Icons.hourglass_bottom_rounded;
  }
}
