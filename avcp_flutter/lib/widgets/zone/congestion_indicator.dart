/// Congestion indicator — color + icon + label (NEVER color alone).
///
/// Implements [Semantics] with a descriptive label for screen readers.
/// Uses [AvenuColors] tokens contrast-tested at 3000K stadium illumination.
/// Supports high-contrast mode via [AvenuHighContrastTheme] extension.
library;

import 'package:flutter/material.dart';

import '../../accessibility/wcag_tokens.dart';
import '../../models/congestion_level.dart';

class CongestionIndicator extends StatelessWidget {
  const CongestionIndicator({
    super.key,
    required this.level,
    required this.zoneName,
    this.compact = false,
  });

  final CongestionLevel level;
  final String zoneName;

  /// If true, shows a compact chip-style indicator.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highContrast =
        theme.extension<AvenuHighContrastTheme>();
    final displayColor = _resolveColor(highContrast);

    return Semantics(
      label: '$zoneName — crowd level: ${level.label}. '
          '${level.semanticDescription}',
      child: compact ? _buildCompact(theme, displayColor) : _buildFull(theme, displayColor),
    );
  }

  Widget _buildFull(ThemeData theme, Color displayColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: displayColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon — never color alone
          Icon(level.icon, color: displayColor, size: 24),
          const SizedBox(width: 12),
          // Label — always paired with icon and color
          Text(
            level.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: displayColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(ThemeData theme, Color displayColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, color: displayColor, size: 16),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: displayColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Resolves the display color, preferring high-contrast overrides.
  Color _resolveColor(AvenuHighContrastTheme? hc) {
    if (hc == null) return level.color;
    return switch (level) {
      CongestionLevel.free => hc.crowdFree,
      CongestionLevel.moderate => hc.crowdModerate,
      CongestionLevel.high => hc.crowdHigh,
      CongestionLevel.critical => hc.crowdCritical,
    };
  }
}
