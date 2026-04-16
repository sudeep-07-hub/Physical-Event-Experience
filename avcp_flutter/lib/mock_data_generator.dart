/// AVCP Mock Data Generator — Triple-Threat UI v1.0.0
///
/// Emits realistic crowd vector and user context streams without
/// any live Firebase dependency. Enables full UI testing via:
///   flutter run --dart-define=MOCK_DATA=true
///
/// Realism model:
/// - Density: sine-wave oscillation (0.5–4.5) over 60s cycle
/// - Heading: slow ±10° drift per tick from base bearing
/// - Dwell ratio: correlated with density (higher → stickier)
/// - Bottleneck: Greenshields model b = 1-(speed/1.4)*(1-density/6.5)
/// - Anomaly: triggers at density > 3.5
/// - Context: cycles through 4 intent scenarios every 40s
library;

import 'dart:math';

import 'package:avcp_flutter/intent_service.dart';
import 'package:avcp_flutter/crowd_vector.dart';

/// Static-only mock data generator. No instances needed.
///
/// All methods return [Stream]s that emit at configurable intervals,
/// producing realistic crowd telemetry without a live backend.
final class MockDataGenerator {
  MockDataGenerator._(); // Prevent instantiation.

  static const double _kJam = 6.5;
  static const double _vFree = 1.4;

  // ── Crowd Vector Stream ───────────────────────────────────────────

  /// Emits a [CrowdVelocityVector] every [interval] with realistic
  /// physics-based values.
  ///
  /// Uses sine-wave density oscillation, Greenshields bottleneck model,
  /// and correlated dwell ratio for plausible crowd dynamics.
  static Stream<CrowdVelocityVector> stream({
    String zoneId = 'gate_c_concourse_l2',
    Duration interval = const Duration(seconds: 2),
  }) async* {
    final Random rng = Random(42);
    double baseBearing = 180.0;
    int tickIndex = 0;

    while (true) {
      await Future<void>.delayed(interval);
      tickIndex++;

      // ── Density: sine wave 0.5–4.5 over ~60s cycle ────────────────
      final double phase = tickIndex * 2.0 * pi / 30.0; // 30 ticks = 60s
      final double density = 2.5 + 2.0 * sin(phase);
      final double densityClamped = density.clamp(0.0, _kJam);

      // ── Speed: inversely correlated with density (Greenshields) ───
      final double speed = (_vFree * (1.0 - densityClamped / _kJam))
          .clamp(0.0, _vFree);

      // ── Heading: slow drift ±10° per tick ─────────────────────────
      baseBearing += (rng.nextDouble() - 0.5) * 20.0;
      baseBearing = baseBearing % 360.0;

      // ── Velocity components from heading + speed ──────────────────
      final double headingRad = baseBearing * pi / 180.0;
      final double vx = speed * sin(headingRad);
      final double vy = speed * cos(headingRad);

      // ── Dwell ratio: correlated with density ──────────────────────
      final double dwellRatio =
          (densityClamped / _kJam * 0.8 + rng.nextDouble() * 0.15)
              .clamp(0.0, 1.0);

      // ── Bottleneck: Greenshields model ────────────────────────────
      final double rawBottleneck =
          1.0 - (speed / _vFree) * (1.0 - densityClamped / _kJam);
      final double bottleneck = rawBottleneck.clamp(0.0, 1.0);

      // ── Flow variance: higher at moderate density (turbulence) ────
      final double flowVar = (densityClamped * (1.0 - densityClamped / _kJam))
              .abs() *
          (2.0 + rng.nextDouble() * 3.0);

      // ── Anomaly flag ──────────────────────────────────────────────
      final bool anomaly = densityClamped > 3.5;

      // ── Confidence ────────────────────────────────────────────────
      final double confidence = 0.85 + rng.nextDouble() * 0.13;

      // ── Predictions ───────────────────────────────────────────────
      final double pred60 = (densityClamped + 0.3 * sin(phase + 0.5))
          .clamp(0.0, _kJam);
      final double pred300 = (densityClamped + 0.8 * sin(phase + 1.5))
          .clamp(0.0, _kJam);

      yield CrowdVelocityVector(
        zoneId: zoneId,
        sectorHash: 'mock_${zoneId.hashCode.toRadixString(16)}',
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        tickWindowS: 2.0,
        densityPpm2: densityClamped,
        velocityX: vx,
        velocityY: vy,
        speedP95: speed * 1.15,
        headingDeg: baseBearing,
        dwellRatio: dwellRatio,
        flowVariance: flowVar,
        bottleneckScore: bottleneck,
        predictedDensity60s: pred60,
        predictedDensity300s: pred300,
        anomalyFlag: anomaly,
        confidence: confidence,
        edgeNodeId: 'mock_edge_001',
        schemaVersion: '2.1.0',
      );
    }
  }

  // ── User Context Stream ───────────────────────────────────────────

  /// Emits a [UserContext] cycling through 4 intent scenarios.
  ///
  /// Cycle (repeats every 40s):
  /// - 0–10s: normal (no action)
  /// - 10–20s: congested (waitTime trigger)
  /// - 20–30s: near gate (ticketQr trigger)
  /// - 30–40s: gridlock (rerouting trigger)
  static Stream<UserContext> contextStream({
    Duration interval = const Duration(seconds: 2),
  }) async* {
    int tickIndex = 0;
    const int cycleTicks = 20; // 20 ticks × 2s = 40s full cycle

    while (true) {
      await Future<void>.delayed(interval);
      tickIndex++;

      final int phase = (tickIndex % cycleTicks);
      final UserContext ctx;

      if (phase < 5) {
        // Normal: no trigger
        ctx = const UserContext(
          uwbProximityMeters: 150.0,
          dwellRatio: 0.30,
          bottleneckScore: 0.20,
          zoneId: 'section_a',
          assignedGateId: 'C',
          waitMinutes: 3,
        );
      } else if (phase < 10) {
        // Congested: waitTime trigger (dwellRatio > 0.60)
        ctx = const UserContext(
          uwbProximityMeters: 150.0,
          dwellRatio: 0.72,
          bottleneckScore: 0.40,
          zoneId: 'gate_c_concourse_l2',
          assignedGateId: 'C',
          waitMinutes: 12,
        );
      } else if (phase < 15) {
        // Near gate: ticketQr trigger (proximity < 30m)
        ctx = const UserContext(
          uwbProximityMeters: 18.0,
          dwellRatio: 0.30,
          bottleneckScore: 0.20,
          zoneId: 'gate_c_entry',
          assignedGateId: 'C',
          waitMinutes: 2,
        );
      } else {
        // Gridlock: rerouting trigger (bottleneck > 0.75)
        ctx = const UserContext(
          uwbProximityMeters: 60.0,
          dwellRatio: 0.50,
          bottleneckScore: 0.82,
          zoneId: 'concourse_level1',
          assignedGateId: 'C',
          waitMinutes: 8,
        );
      }

      yield ctx;
    }
  }
}
