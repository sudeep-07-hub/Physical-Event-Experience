/// Widget tests for [ContextualActionBanner].
///
/// Tests:
/// 1. Shows TicketQRSurface for showTicketQR intent
/// 2. Shows WaitTimeBanner for showWaitTime intent
/// 3. Shows AlternateRouteSuggestion for offerAlternateRoute intent
/// 4. Shows nothing for IntentNone
/// 5. Auto-dismisses after 8 seconds
/// 6. Dismiss on user action (close button)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avcp_flutter/models/user_context.dart';
import 'package:avcp_flutter/models/user_intent.dart';
import 'package:avcp_flutter/providers/intent_providers.dart';
import 'package:avcp_flutter/providers/service_providers.dart';
import 'package:avcp_flutter/services/intent_detection_service.dart';
import 'package:avcp_flutter/widgets/banner/contextual_action_banner.dart';
import 'package:avcp_flutter/widgets/banner/ticket_qr_surface.dart';
import 'package:avcp_flutter/widgets/banner/wait_time_banner.dart';
import 'package:avcp_flutter/widgets/banner/alternate_route_suggestion.dart';

/// Stub intent detection service for testing.
class _StubIntentService implements IntentDetectionService {
  _StubIntentService(this.intent);
  final UserIntent intent;

  @override
  UserIntent detectFromContext(UserContext ctx) => intent;
}

void main() {
  group('ContextualActionBanner', () {
    Widget buildTestWidget(UserIntent intent) {
      return ProviderScope(
        overrides: [
          intentDetectionServiceProvider.overrideWithValue(
            _StubIntentService(intent),
          ),
          userContextProvider.overrideWith(
            (_) => const UserContext(currentZoneId: 'test_zone'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SafeArea(child: ContextualActionBanner()),
          ),
        ),
      );
    }

    testWidgets('shows nothing for IntentNone', (tester) async {
      await tester.pumpWidget(buildTestWidget(const UserIntent.none()));
      await tester.pump();
      expect(find.byType(TicketQRSurface), findsNothing);
      expect(find.byType(WaitTimeBanner), findsNothing);
      expect(find.byType(AlternateRouteSuggestion), findsNothing);
    });

    testWidgets('shows TicketQRSurface for showTicketQR intent',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const UserIntent.showTicketQR(
            gateId: 'C',
            distanceMetres: 15.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TicketQRSurface), findsOneWidget);
      expect(find.text('Gate C'), findsOneWidget);
    });

    testWidgets('shows WaitTimeBanner for showWaitTime intent',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const UserIntent.showWaitTime(
            zoneId: 'gate_c',
            dwellRatio: 0.7,
            estimatedWaitMinutes: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WaitTimeBanner), findsOneWidget);
      expect(find.text('Est. wait: 5 min'), findsOneWidget);
    });

    testWidgets('shows AlternateRouteSuggestion for offerAlternateRoute',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const UserIntent.offerAlternateRoute(
            fromZoneId: 'gate_c',
            suggestedZoneId: 'gate_d',
            bottleneckScore: 0.85,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlternateRouteSuggestion), findsOneWidget);
      expect(find.textContaining('85%'), findsOneWidget);
    });

    testWidgets('auto-dismisses after 8 seconds', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const UserIntent.showWaitTime(
            zoneId: 'gate_c',
            dwellRatio: 0.7,
            estimatedWaitMinutes: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WaitTimeBanner), findsOneWidget);

      // Advance past the 8-second auto-dismiss
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.byType(WaitTimeBanner), findsNothing);
    });

    testWidgets('dismiss on close button tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const UserIntent.showWaitTime(
            zoneId: 'gate_c',
            dwellRatio: 0.7,
            estimatedWaitMinutes: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WaitTimeBanner), findsOneWidget);

      // Tap the close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(WaitTimeBanner), findsNothing);
    });
  });
}
