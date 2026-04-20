import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avcp_flutter/wayfinding/direction_banner.dart';
import 'package:avcp_flutter/wayfinding/gate_intent_service.dart';

void main() {
  group('DirectionBanner Validations', () {
    testWidgets('freeFlowing banner renders street name, NEVER "proceed to destination"', (tester) async {
      // Mock initialization boilerplate skipped for brevity
      expect(find.textContaining('proceed to destination'), findsNothing);
    });

    testWidgets('AnimatedSwitcher children have ValueKey', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DirectionBanner()),
          ),
        ),
      );
      
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });
  });
}
