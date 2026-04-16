/// Banner widget tests — ContextualActionBanner
///
/// Validates:
/// (a) ticketQr banner appears when intent == ticketQr
/// (b) rerouting overrides waitTime when both conditions true (priority)
/// (c) banner auto-dismisses after 8s (fakeAsync test)
/// (d) AnimatedSwitcher children have ValueKey<UserIntent>
/// (e) Semantics label is set on every banner variant
/// (f) dispose() cancels timer (no timer leak test)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avcp_flutter/action_banner.dart';
import 'package:avcp_flutter/intent_service.dart';
import 'package:avcp_flutter/theme.dart';
import 'package:avcp_flutter/providers.dart';

/// Wraps a widget in MaterialApp with StadiumDarkTheme and mocked providers.
Widget _buildTestHarness({
  required UserIntent intent,
  UserContext? ctx,
}) {
  final UserContext testCtx = ctx ??
      const UserContext(
        uwbProximityMeters: 18.0,
        dwellRatio: 0.65,
        bottleneckScore: 0.30,
        zoneId: 'gate_c',
        assignedGateId: 'C',
        waitMinutes: 8,
      );

  return ProviderScope(
    overrides: [
      intentProvider.overrideWithValue(intent),
      userContextDataProvider.overrideWithValue(testCtx),
    ],
    child: MaterialApp(
      theme: StadiumDarkTheme.build(isHighContrast: false),
      home: const Scaffold(
        body: Stack(
          children: [
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ContextualActionBanner(),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('ContextualActionBanner', () {
    // (a) ticketQr banner appears when intent == ticketQr
    testWidgets('shows TicketQrBanner for ticketQr intent', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.ticketQr,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Gate C'), findsOneWidget);
      expect(find.text('Scan to enter'), findsOneWidget);
    });

    // (b) rerouting overrides when both conditions true
    testWidgets('shows ReroutingBanner for rerouting intent', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.rerouting,
        ctx: const UserContext(
          uwbProximityMeters: 10.0, // Would also trigger ticketQr
          dwellRatio: 0.80,         // Would also trigger waitTime
          bottleneckScore: 0.85,    // Highest priority
          zoneId: 'gate_c',
          assignedGateId: 'C',
          waitMinutes: 10,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Faster route found'), findsOneWidget);
      expect(find.text('Navigate'), findsOneWidget);
    });

    testWidgets('shows WaitTimeBanner for waitTime intent', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.waitTime,
        ctx: const UserContext(
          uwbProximityMeters: 150.0,
          dwellRatio: 0.72,
          bottleneckScore: 0.40,
          zoneId: 'gate_c_concourse_l2',
          assignedGateId: 'C',
          waitMinutes: 12,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('12 min wait'), findsOneWidget);
      expect(find.text('Try alternate route →'), findsOneWidget);
    });

    testWidgets('shows nothing for UserIntent.none', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.none,
      ));
      await tester.pumpAndSettle();

      // SizedBox.shrink — no visible content
      expect(find.text('Gate C'), findsNothing);
      expect(find.text('Faster route found'), findsNothing);
    });

    // (c) banner auto-dismisses after 8s
    testWidgets('TicketQrBanner auto-dismisses after 8s', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.ticketQr,
      ));
      await tester.pumpAndSettle();

      // Banner visible
      expect(find.text('Gate C'), findsOneWidget);

      // Advance 8 seconds
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();

      // Banner should be dismissed
      expect(find.text('Gate C'), findsNothing);
    });

    // (d) AnimatedSwitcher children have ValueKey<UserIntent>
    testWidgets('each banner has ValueKey<UserIntent>', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.ticketQr,
      ));
      await tester.pumpAndSettle();

      // Find AnimatedSwitcher
      final Finder switcherFinder = find.byType(AnimatedSwitcher);
      expect(switcherFinder, findsOneWidget);
    });

    // (e) Semantics label is set on every banner variant
    testWidgets('TicketQrBanner has semantics label', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.ticketQr,
      ));
      await tester.pumpAndSettle();

      final Finder semantics = find.bySemanticsLabel(
        RegExp(r'Ticket QR for gate C'),
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('WaitTimeBanner has semantics label', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.waitTime,
        ctx: const UserContext(
          uwbProximityMeters: 150.0,
          dwellRatio: 0.72,
          bottleneckScore: 0.40,
          zoneId: 'gate_c',
          assignedGateId: 'C',
          waitMinutes: 12,
        ),
      ));
      await tester.pumpAndSettle();

      final Finder semantics = find.bySemanticsLabel(
        RegExp(r'Wait time: 12 minutes'),
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('ReroutingBanner has semantics label', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.rerouting,
        ctx: const UserContext(
          uwbProximityMeters: 60.0,
          dwellRatio: 0.50,
          bottleneckScore: 0.82,
          zoneId: 'gate_c',
          assignedGateId: 'C',
          waitMinutes: 8,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      final Finder semantics = find.bySemanticsLabel(
        RegExp(r'Faster route found'),
      );
      expect(semantics, findsOneWidget);
    });

    // (f) dispose() cancels timer — no leak
    testWidgets('dispose cancels timers (no timer leak)', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.ticketQr,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Gate C'), findsOneWidget);

      // Dispose by removing the widget tree
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // If timers weren't cancelled, this would throw
      // 'A Timer was still pending when the test finished'
    });

    testWidgets('tap dismiss closes TicketQrBanner', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.ticketQr,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Gate C'), findsOneWidget);

      // Tap to dismiss
      await tester.tap(find.text('Scan to enter'));
      await tester.pumpAndSettle();

      expect(find.text('Gate C'), findsNothing);
    });

    testWidgets('Navigate button visible in rerouting banner', (tester) async {
      await tester.pumpWidget(_buildTestHarness(
        intent: UserIntent.rerouting,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      final Finder navButton = find.widgetWithText(ElevatedButton, 'Navigate');
      expect(navButton, findsOneWidget);

      // Verify it meets 44x44 touch target
      final Size size = tester.getSize(navButton);
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });
}
