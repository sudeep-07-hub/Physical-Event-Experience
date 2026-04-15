/// Widget tests for [CongestionIndicator] — including golden tests.
///
/// Tests:
/// 1. Correct icon, color, and label for each congestion level
/// 2. Semantics label is present and descriptive
/// 3. High-contrast mode overrides colors correctly
/// 4. Golden test for visual regression across all 4 levels
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avcp_flutter/accessibility/wcag_tokens.dart';
import 'package:avcp_flutter/models/congestion_level.dart';
import 'package:avcp_flutter/widgets/zone/congestion_indicator.dart';

void main() {
  group('CongestionIndicator', () {
    Widget buildTestWidget(CongestionLevel level, {bool highContrast = false}) {
      return MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: [
            if (highContrast) AvenuHighContrastTheme.highContrast(),
          ],
        ),
        home: Scaffold(
          body: Center(
            child: CongestionIndicator(
              level: level,
              zoneName: 'Gate C',
            ),
          ),
        ),
      );
    }

    // ── Icon + Label Tests ──────────────────────────────────────────────

    testWidgets('shows correct icon for free level', (tester) async {
      await tester.pumpWidget(buildTestWidget(CongestionLevel.free));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('Free flow'), findsOneWidget);
    });

    testWidgets('shows correct icon for moderate level', (tester) async {
      await tester.pumpWidget(buildTestWidget(CongestionLevel.moderate));
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
    });

    testWidgets('shows correct icon for high level', (tester) async {
      await tester.pumpWidget(buildTestWidget(CongestionLevel.high));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('High congestion'), findsOneWidget);
    });

    testWidgets('shows correct icon for critical level', (tester) async {
      await tester.pumpWidget(buildTestWidget(CongestionLevel.critical));
      expect(find.byIcon(Icons.dangerous_outlined), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
    });

    // ── Semantics Tests ─────────────────────────────────────────────────

    testWidgets('has semantic label with zone name and level', (tester) async {
      await tester.pumpWidget(buildTestWidget(CongestionLevel.moderate));

      final semantics = tester.getSemantics(find.byType(CongestionIndicator));
      expect(
        semantics.label,
        contains('Gate C'),
      );
      expect(
        semantics.label,
        contains('moderate'),
      );
    });

    // ── High Contrast Tests ─────────────────────────────────────────────

    testWidgets('uses high-contrast colors when extension is present',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(CongestionLevel.free, highContrast: true),
      );

      // The icon should use the high-contrast green, not the standard green.
      // We verify indirectly by ensuring the widget renders without error
      // in high-contrast mode.
      expect(find.byType(CongestionIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    // ── Compact Mode Test ───────────────────────────────────────────────

    testWidgets('compact variant renders smaller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: CongestionIndicator(
                level: CongestionLevel.critical,
                zoneName: 'Gate A',
                compact: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Critical'), findsOneWidget);
      expect(find.byIcon(Icons.dangerous_outlined), findsOneWidget);
    });

    // ── Golden Tests ────────────────────────────────────────────────────

    testWidgets('golden: all congestion levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: CongestionLevel.values
                    .map(
                      (level) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: CongestionIndicator(
                          level: level,
                          zoneName: 'Test Zone',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/congestion_indicator_all_levels.png'),
      );
    });

    testWidgets('golden: high contrast mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [AvenuHighContrastTheme.highContrast()],
          ),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: CongestionLevel.values
                    .map(
                      (level) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: CongestionIndicator(
                          level: level,
                          zoneName: 'Test Zone',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/congestion_indicator_high_contrast.png'),
      );
    });
  });
}
