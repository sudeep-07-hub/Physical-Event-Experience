/// Unit tests for [CrowdAnalysisServiceImpl].
///
/// Tests:
/// 1. Classification thresholds match Fruin LoS levels
/// 2. Alert generation for congestion, bottleneck, anomaly, predictive
/// 3. Wait time estimation heuristic
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:avcp_flutter/models/congestion_level.dart';
import 'package:avcp_flutter/crowd_vector.dart';
import 'package:avcp_flutter/models/zone_alert.dart';
import 'package:avcp_flutter/services/crowd_analysis_service_impl.dart';

void main() {
  late CrowdAnalysisServiceImpl service;

  setUp(() {
    service = CrowdAnalysisServiceImpl();
  });

  CrowdVelocityVector _makeVector({
    double densityPpm2 = 0.0,
    double dwellRatio = 0.0,
    double bottleneckScore = 0.0,
    bool anomalyFlag = false,
    double predictedDensity60s = 0.0,
  }) {
    return CrowdVelocityVector(
      zoneId: 'test_zone',
      sectorHash: 'abc123',
      timestampMs: 1700000000000,
      densityPpm2: densityPpm2,
      dwellRatio: dwellRatio,
      bottleneckScore: bottleneckScore,
      anomalyFlag: anomalyFlag,
      predictedDensity60s: predictedDensity60s,
    );
  }

  group('classify', () {
    test('density < 1.0 → free', () {
      expect(
        service.classify(_makeVector(densityPpm2: 0.5)),
        CongestionLevel.free,
      );
    });

    test('density 1.0 → moderate', () {
      expect(
        service.classify(_makeVector(densityPpm2: 1.0)),
        CongestionLevel.moderate,
      );
    });

    test('density 2.4 → moderate', () {
      expect(
        service.classify(_makeVector(densityPpm2: 2.4)),
        CongestionLevel.moderate,
      );
    });

    test('density 2.5 → high', () {
      expect(
        service.classify(_makeVector(densityPpm2: 2.5)),
        CongestionLevel.high,
      );
    });

    test('density 3.9 → high', () {
      expect(
        service.classify(_makeVector(densityPpm2: 3.9)),
        CongestionLevel.high,
      );
    });

    test('density 4.0 → critical', () {
      expect(
        service.classify(_makeVector(densityPpm2: 4.0)),
        CongestionLevel.critical,
      );
    });

    test('density 6.5 (Fruin crush) → critical', () {
      expect(
        service.classify(_makeVector(densityPpm2: 6.5)),
        CongestionLevel.critical,
      );
    });
  });

  group('getAlerts', () {
    test('no alerts for free-flow zones', () {
      final alerts = service.getAlerts([
        _makeVector(densityPpm2: 0.5),
      ]);
      expect(alerts, isEmpty);
    });

    test('congestion warning at density >= 2.5', () {
      final alerts = service.getAlerts([
        _makeVector(densityPpm2: 3.0),
      ]);
      expect(
        alerts.any((a) => a.alertType == AlertType.congestionWarning),
        isTrue,
      );
    });

    test('bottleneck alert when score > 0.75', () {
      final alerts = service.getAlerts([
        _makeVector(bottleneckScore: 0.8),
      ]);
      expect(
        alerts.any((a) => a.alertType == AlertType.bottleneckDetected),
        isTrue,
      );
    });

    test('anomaly alert when flag is true', () {
      final alerts = service.getAlerts([
        _makeVector(anomalyFlag: true),
      ]);
      expect(
        alerts.any((a) => a.alertType == AlertType.anomalyDetected),
        isTrue,
      );
    });

    test('predictive surge when T+60s > 1.5x current', () {
      final alerts = service.getAlerts([
        _makeVector(densityPpm2: 2.0, predictedDensity60s: 4.0),
      ]);
      expect(
        alerts.any((a) => a.alertType == AlertType.predictiveSurge),
        isTrue,
      );
    });

    test('alerts sorted by severity (critical first)', () {
      final alerts = service.getAlerts([
        _makeVector(densityPpm2: 3.0), // high
        _makeVector(densityPpm2: 5.0, bottleneckScore: 0.9), // critical
      ]);
      if (alerts.length >= 2) {
        expect(
          alerts.first.severity.severityIndex >=
              alerts.last.severity.severityIndex,
          isTrue,
        );
      }
    });
  });

  group('estimateWaitMinutes', () {
    test('low density + low dwell → ~0 min', () {
      final minutes = service.estimateWaitMinutes(
        _makeVector(densityPpm2: 0.5, dwellRatio: 0.2),
      );
      expect(minutes, lessThanOrEqualTo(1));
    });

    test('high density + high dwell → several minutes', () {
      final minutes = service.estimateWaitMinutes(
        _makeVector(densityPpm2: 4.0, dwellRatio: 0.8),
      );
      expect(minutes, greaterThanOrEqualTo(5));
    });

    test('result clamped to [0, 30]', () {
      final minutes = service.estimateWaitMinutes(
        _makeVector(densityPpm2: 6.5, dwellRatio: 1.0),
      );
      expect(minutes, lessThanOrEqualTo(30));
      expect(minutes, greaterThanOrEqualTo(0));
    });
  });
}
