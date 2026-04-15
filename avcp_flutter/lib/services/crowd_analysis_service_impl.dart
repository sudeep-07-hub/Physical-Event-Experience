/// Concrete implementation of [CrowdAnalysisService].
///
/// Uses Greenshields model density thresholds for classification
/// and multi-signal alerting logic.
library;

import '../models/congestion_level.dart';
import '../models/crowd_velocity_vector.dart';
import '../models/zone_alert.dart';
import 'crowd_analysis_service.dart';

class CrowdAnalysisServiceImpl implements CrowdAnalysisService {
  // ── Density thresholds (persons per square metre) ──────────────────────
  static const double _freeThreshold = 1.0; // LoS A–B
  static const double _moderateThreshold = 2.5; // LoS C–D
  static const double _highThreshold = 4.0; // LoS E

  // ── Alert thresholds ──────────────────────────────────────────────────
  static const double _bottleneckAlertThreshold = 0.75;
  static const double _predictiveSurgeMultiplier = 1.5;

  @override
  CongestionLevel classify(CrowdVelocityVector vector) {
    final density = vector.densityPpm2;
    if (density < _freeThreshold) return CongestionLevel.free;
    if (density < _moderateThreshold) return CongestionLevel.moderate;
    if (density < _highThreshold) return CongestionLevel.high;
    return CongestionLevel.critical;
  }

  @override
  List<ZoneAlert> getAlerts(List<CrowdVelocityVector> vectors) {
    final alerts = <ZoneAlert>[];

    for (final v in vectors) {
      final level = classify(v);

      // Congestion warning: density hits LoS-E or worse
      if (v.densityPpm2 >= _moderateThreshold) {
        alerts.add(ZoneAlert(
          zoneId: v.zoneId,
          alertType: AlertType.congestionWarning,
          severity: level,
          message:
              'Zone ${v.zoneId}: density ${v.densityPpm2.toStringAsFixed(1)} p/m² '
              '(${level.label})',
          timestampMs: v.timestampMs,
        ));
      }

      // Bottleneck detected
      if (v.bottleneckScore > _bottleneckAlertThreshold) {
        alerts.add(ZoneAlert(
          zoneId: v.zoneId,
          alertType: AlertType.bottleneckDetected,
          severity: CongestionLevel.critical,
          message:
              'Zone ${v.zoneId}: bottleneck score ${v.bottleneckScore.toStringAsFixed(2)} '
              '— flow gridlock imminent',
          timestampMs: v.timestampMs,
        ));
      }

      // Anomaly detected
      if (v.anomalyFlag) {
        alerts.add(ZoneAlert(
          zoneId: v.zoneId,
          alertType: AlertType.anomalyDetected,
          severity: CongestionLevel.high,
          message:
              'Zone ${v.zoneId}: anomaly detected (>2σ deviation from baseline)',
          timestampMs: v.timestampMs,
        ));
      }

      // Predictive surge: T+60s density significantly exceeds current
      if (v.predictedDensity60s >
          v.densityPpm2 * _predictiveSurgeMultiplier) {
        alerts.add(ZoneAlert(
          zoneId: v.zoneId,
          alertType: AlertType.predictiveSurge,
          severity: CongestionLevel.high,
          message:
              'Zone ${v.zoneId}: predicted density surge to '
              '${v.predictedDensity60s.toStringAsFixed(1)} p/m² in 60s',
          timestampMs: v.timestampMs,
        ));
      }
    }

    // Sort by severity (critical first)
    alerts.sort(
      (a, b) => b.severity.severityIndex.compareTo(a.severity.severityIndex),
    );

    return alerts;
  }

  @override
  int estimateWaitMinutes(CrowdVelocityVector vector) {
    // Heuristic: wait time scales with density and dwell ratio.
    // At density=4.0 and dwellRatio=1.0, wait ≈ 12 minutes.
    // At density=1.0 and dwellRatio=0.3, wait ≈ 1 minute.
    final rawMinutes = vector.densityPpm2 * vector.dwellRatio * 3.0;
    return rawMinutes.ceil().clamp(0, 30);
  }
}
