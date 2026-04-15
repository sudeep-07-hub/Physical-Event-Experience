/// Congestion classification levels aligned with Fruin Level-of-Service.
///
/// Each level carries its own color token (from [AvenuColors]),
/// icon, and semantic label — WCAG 2.1 mandates never relying on color alone.
library;

import 'package:flutter/material.dart';

/// Discrete congestion classification, mapped from continuous density values
/// via the Greenshields model in [CrowdAnalysisService].
enum CongestionLevel {
  /// LoS A–B: density < 1.0 p/m², free-flow movement.
  free(
    label: 'Free flow',
    icon: Icons.check_circle_outline,
    colorValue: 0xFF1B5E20, // 7.2:1 on white
    severityIndex: 0,
  ),

  /// LoS C–D: density 1.0–2.5 p/m², restricted but moving.
  moderate(
    label: 'Moderate',
    icon: Icons.info_outline,
    colorValue: 0xFFE65100, // 4.8:1 on white
    severityIndex: 1,
  ),

  /// LoS E: density 2.5–4.0 p/m², significant congestion.
  high(
    label: 'High congestion',
    icon: Icons.warning_amber_rounded,
    colorValue: 0xFFF57F17, // 5.1:1 on dark
    severityIndex: 2,
  ),

  /// LoS F: density > 4.0 p/m², crush risk — immediate action required.
  critical(
    label: 'Critical',
    icon: Icons.dangerous_outlined,
    colorValue: 0xFFB71C1C, // 8.1:1 on white
    severityIndex: 3,
  );

  const CongestionLevel({
    required this.label,
    required this.icon,
    required this.colorValue,
    required this.severityIndex,
  });

  /// Human-readable label for UI and screen readers.
  final String label;

  /// Icon that pairs with color — never color alone (WCAG 1.4.1).
  final IconData icon;

  /// Raw ARGB color value. Use [color] getter for the [Color] object.
  final int colorValue;

  /// 0 = lowest severity, 3 = highest. Used for sorting alerts.
  final int severityIndex;

  /// Convenience getter for Flutter [Color].
  Color get color => Color(colorValue);

  /// Semantic description for screen readers.
  String get semanticDescription => switch (this) {
        CongestionLevel.free => 'Area is uncrowded with free movement.',
        CongestionLevel.moderate => 'Area has moderate crowd density.',
        CongestionLevel.high =>
          'Area is highly congested. Consider alternate routes.',
        CongestionLevel.critical =>
          'Critical crowd density. Seek alternate route immediately.',
      };
}
