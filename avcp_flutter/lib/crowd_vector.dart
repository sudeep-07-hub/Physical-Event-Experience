/// CrowdVelocityVector — immutable Dart mirror of the Python schema.
///
/// Field names use Dart camelCase but serialize to Python snake_case via
/// `@JsonKey(name: ...)` to ensure zero-friction Firebase RTDB round-trips.
///
/// This model is a 1:1 match of `avcp/schema.py::CrowdVelocityVector`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'crowd_vector.freezed.dart';
part 'crowd_vector.g.dart';

@freezed
class CrowdVelocityVector with _$CrowdVelocityVector {
  const CrowdVelocityVector._();

  const factory CrowdVelocityVector({
    // ── Spatial identity (zone-level, never device-level) ──────────────
    @JsonKey(name: 'zone_id') required String zoneId,

    @JsonKey(name: 'sector_hash') required String sectorHash,

    @JsonKey(name: 'timestamp_ms') required int timestampMs,

    @JsonKey(name: 'tick_window_s') @Default(2.0) double tickWindowS,

    // ── Kinematic fields ──────────────────────────────────────────────
    /// People per square metre. Clamped to [0.0, 6.5] (Fruin LoS-F).
    @JsonKey(name: 'density_ppm2') @Default(0.0) double densityPpm2,

    /// Mean lateral flow m/s, signed (−=west, +=east).
    @JsonKey(name: 'velocity_x') @Default(0.0) double velocityX,

    /// Mean longitudinal flow m/s, signed (−=south, +=north).
    @JsonKey(name: 'velocity_y') @Default(0.0) double velocityY,

    /// 95th-percentile scalar speed m/s.
    @JsonKey(name: 'speed_p95') @Default(0.0) double speedP95,

    /// Dominant heading [0, 360), 0=North.
    @JsonKey(name: 'heading_deg') @Default(0.0) double headingDeg,

    // ── Congestion signals ────────────────────────────────────────────
    /// Fraction of population with speed < 0.3 m/s. Range [0, 1].
    @JsonKey(name: 'dwell_ratio') @Default(0.0) double dwellRatio,

    /// Kinetic-energy variance (turbulence proxy).
    @JsonKey(name: 'flow_variance') @Default(0.0) double flowVariance,

    /// 0=free-flow, 1=gridlock. Computed via Greenshields model.
    @JsonKey(name: 'bottleneck_score') @Default(0.0) double bottleneckScore,

    // ── Predictive annotations (Vertex AI / TFLite at edge) ───────────
    /// Forecast density at T+60 s.
    @JsonKey(name: 'predicted_density_60s')
    @Default(0.0)
    double predictedDensity60s,

    /// Forecast density at T+5 min.
    @JsonKey(name: 'predicted_density_300s')
    @Default(0.0)
    double predictedDensity300s,

    /// True if deviation > 2σ from a rolling 15-min baseline.
    @JsonKey(name: 'anomaly_flag') @Default(false) bool anomalyFlag,

    /// Model confidence [0, 1].
    @Default(0.0) double confidence,

    // ── Operational metadata ──────────────────────────────────────────
    /// Anonymized edge-node UUID, regenerated per session startup.
    @JsonKey(name: 'edge_node_id') @Default('') String edgeNodeId,

    /// Semver schema version string.
    @JsonKey(name: 'schema_version') @Default('2.1.0') String schemaVersion,
  }) = _CrowdVelocityVector;

  factory CrowdVelocityVector.fromJson(Map<String, dynamic> json) =>
      _$CrowdVelocityVectorFromJson(json);

  /// Compute scalar speed from (velocityX, velocityY).
  double get speedScalar {
    return (velocityX * velocityX + velocityY * velocityY).clampedSqrt();
  }
}

/// Extension to avoid importing `dart:math` into a Freezed file.
extension on double {
  double clampedSqrt() {
    if (this <= 0) return 0.0;
    // Newton's method — fast enough for a single value.
    double guess = this / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + this / guess) / 2;
    }
    return guess;
  }
}
