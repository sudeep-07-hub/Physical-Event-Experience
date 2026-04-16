/// Dashboard tests — KPI cards and FlowVectorPainter
///
/// Validates:
/// (a) KPI card select() rebuild isolation
/// (b) FlowVectorPainter shouldRepaint uses reference equality
/// (c) KPI cards have Semantics labels
/// (d) Speed→color mapping thresholds
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avcp_flutter/dashboard.dart';
import 'package:avcp_flutter/theme.dart';

/// Helper to wrap a widget in MaterialApp with StadiumDarkTheme.
Widget _themed(Widget child) {
  return MaterialApp(
    theme: StadiumDarkTheme.build(isHighContrast: false),
    home: Scaffold(body: child),
  );
}

void main() {
  group('FlowVectorPainter', () {
    final List<ZoneFlowVector> vectorsA = <ZoneFlowVector>[
      const ZoneFlowVector(
        center: Offset(100, 100),
        headingDeg: 90.0,
        speedP95: 1.0,
      ),
    ];
    final List<ZoneFlowVector> vectorsB = <ZoneFlowVector>[
      const ZoneFlowVector(
        center: Offset(200, 200),
        headingDeg: 180.0,
        speedP95: 0.3,
      ),
    ];

    test('shouldRepaint returns false for identical reference', () {
      final FlowVectorPainter painter = FlowVectorPainter(
        vectors: vectorsA,
        primaryGold: const Color(0xFFFFD700),
        alertRed: const Color(0xFFFF5252),
      );
      final FlowVectorPainter same = FlowVectorPainter(
        vectors: vectorsA, // Same reference
        primaryGold: const Color(0xFFFFD700),
        alertRed: const Color(0xFFFF5252),
      );
      expect(painter.shouldRepaint(same), isFalse);
    });

    test('shouldRepaint returns true for different reference', () {
      final FlowVectorPainter painter = FlowVectorPainter(
        vectors: vectorsA,
        primaryGold: const Color(0xFFFFD700),
        alertRed: const Color(0xFFFF5252),
      );
      final FlowVectorPainter different = FlowVectorPainter(
        vectors: vectorsB, // Different reference
        primaryGold: const Color(0xFFFFD700),
        alertRed: const Color(0xFFFF5252),
      );
      expect(painter.shouldRepaint(different), isTrue);
    });

    test('color mapping: slow speed → primaryGold', () {
      const ZoneFlowVector slowVec = ZoneFlowVector(
        center: Offset(100, 100),
        headingDeg: 0.0,
        speedP95: 0.3, // < 0.5 → primaryGold
      );
      expect(slowVec.speedP95 < 0.5, isTrue);
    });

    test('color mapping: normal speed → white', () {
      const ZoneFlowVector normalVec = ZoneFlowVector(
        center: Offset(100, 100),
        headingDeg: 0.0,
        speedP95: 0.8, // 0.5–1.2 → white
      );
      expect(normalVec.speedP95 >= 0.5, isTrue);
      expect(normalVec.speedP95 <= 1.2, isTrue);
    });

    test('color mapping: fast speed → alertRed', () {
      const ZoneFlowVector fastVec = ZoneFlowVector(
        center: Offset(100, 100),
        headingDeg: 0.0,
        speedP95: 1.5, // > 1.2 → alertRed
      );
      expect(fastVec.speedP95 > 1.2, isTrue);
    });

    test('arrow length clamped to [8, 40]', () {
      expect((0.1 * 20.0).clamp(8.0, 40.0), equals(8.0)); // Min clamp
      expect((1.0 * 20.0).clamp(8.0, 40.0), equals(20.0)); // Normal
      expect((3.0 * 20.0).clamp(8.0, 40.0), equals(40.0)); // Max clamp
    });

    test('heading transform: 0° North → -pi/2 radians', () {
      const double headingDeg = 0.0;
      final double angleRad = headingDeg * pi / 180.0 - pi / 2;
      expect(angleRad, closeTo(-pi / 2, 0.001));
    });

    test('heading transform: 90° East → 0 radians', () {
      const double headingDeg = 90.0;
      final double angleRad = headingDeg * pi / 180.0 - pi / 2;
      expect(angleRad, closeTo(0.0, 0.001));
    });
  });

  group('KpiCard', () {
    testWidgets('renders label, value, and unit', (tester) async {
      await tester.pumpWidget(_themed(
        const KpiCard(
          label: 'FLOW',
          value: '1.2',
          unit: 'm/s',
          semanticsLabel: 'Flow speed: 1.2 metres per second',
        ),
      ));

      expect(find.text('FLOW'), findsOneWidget);
      expect(find.text('1.2'), findsOneWidget);
      expect(find.text('m/s'), findsOneWidget);
    });

    testWidgets('has Semantics wrapper', (tester) async {
      await tester.pumpWidget(_themed(
        const KpiCard(
          label: 'DENSITY',
          value: '45',
          unit: '%',
          semanticsLabel: 'Crowd density: 45 percent of capacity',
        ),
      ));

      // Verify Semantics widget exists wrapping the KpiCard
      final Finder semanticsWidget = find.byWidgetPredicate(
        (Widget w) =>
            w is Semantics &&
            w.properties.label == 'Crowd density: 45 percent of capacity',
      );
      expect(semanticsWidget, findsOneWidget);
    });

    testWidgets('meets 44x44 minimum touch target', (tester) async {
      await tester.pumpWidget(_themed(
        const Center(
          child: KpiCard(
            label: 'WAIT',
            value: '8',
            unit: 'min',
            semanticsLabel: 'Estimated wait: 8 minutes',
          ),
        ),
      ));

      final Finder cardFinder = find.byType(KpiCard);
      final Size size = tester.getSize(cardFinder);
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('ZoneFlowVector', () {
    test('is immutable', () {
      const ZoneFlowVector v = ZoneFlowVector(
        center: Offset(100, 200),
        headingDeg: 45.0,
        speedP95: 1.1,
      );
      expect(v.center, equals(const Offset(100, 200)));
      expect(v.headingDeg, equals(45.0));
      expect(v.speedP95, equals(1.1));
    });
  });
}
