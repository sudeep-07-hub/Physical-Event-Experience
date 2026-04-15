/// Crowd analysis service — abstract interface.
///
/// Pure Dart. No Flutter imports. 100% testable.
library;

import '../models/congestion_level.dart';
import '../models/crowd_velocity_vector.dart';
import '../models/zone_alert.dart';

/// Classifies crowd vectors into congestion levels and generates alerts.
///
/// Implementation uses Greenshields model density/velocity thresholds:
/// - Free: density < 1.0 p/m²
/// - Moderate: 1.0 ≤ density < 2.5 p/m²
/// - High: 2.5 ≤ density < 4.0 p/m²
/// - Critical: density ≥ 4.0 p/m² (Fruin LoS-F)
abstract class CrowdAnalysisService {
  /// Classify a single vector into a [CongestionLevel].
  CongestionLevel classify(CrowdVelocityVector vector);

  /// Generate alerts from a list of zone vectors.
  ///
  /// Alerts are produced when:
  /// - density_ppm2 ≥ 2.5 (congestion warning)
  /// - bottleneck_score > 0.75 (bottleneck detected)
  /// - anomaly_flag is true (anomaly detected)
  /// - predicted_density_60s exceeds current threshold by 50%+
  List<ZoneAlert> getAlerts(List<CrowdVelocityVector> vectors);

  /// Returns the estimated wait time in minutes for a zone based on
  /// dwell ratio and density.
  int estimateWaitMinutes(CrowdVelocityVector vector);
}
