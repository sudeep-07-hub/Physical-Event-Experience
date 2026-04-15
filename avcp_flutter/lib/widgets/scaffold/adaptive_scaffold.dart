/// Adaptive scaffold that handles phones, foldables, and tablets.
///
/// Layout strategy:
/// - Compact (<600dp): single-pane with map, banner overlay, bottom sheet
/// - Medium (600–840dp): side-by-side map + zone detail
/// - Expanded (>840dp): full dashboard layout (operator mode)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_context.dart';
import '../../providers/intent_providers.dart';
import '../banner/contextual_action_banner.dart';
import '../map/venue_map_view.dart';
import '../operator/operator_dashboard.dart';

/// Breakpoints aligned with Material 3 adaptive layout guidance.
const double _compactBreakpoint = 600;
const double _expandedBreakpoint = 840;

class AdaptiveScaffold extends ConsumerWidget {
  const AdaptiveScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userContext = ref.watch(userContextProvider);
    final isOperator = userContext.role == UserRole.operator;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Expanded: operator gets full dashboard
          if (width >= _expandedBreakpoint && isOperator) {
            return const Row(
              children: [
                Expanded(flex: 3, child: _MapPane()),
                Expanded(flex: 2, child: OperatorDashboard()),
              ],
            );
          }

          // Medium: side-by-side map + contextual panel
          if (width >= _compactBreakpoint) {
            return const Row(
              children: [
                Expanded(flex: 3, child: _MapPane()),
                Expanded(flex: 2, child: _ContextualPanel()),
              ],
            );
          }

          // Compact: map with overlay banner
          return const _MapPane();
        },
      ),
    );
  }
}

/// Map pane with contextual action banner overlay.
class _MapPane extends StatelessWidget {
  const _MapPane();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        VenueMapView(),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: ContextualActionBanner()),
        ),
      ],
    );
  }
}

/// Right-side contextual panel for medium-width layouts.
class _ContextualPanel extends StatelessWidget {
  const _ContextualPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: const Column(
        children: [
          SafeArea(child: ContextualActionBanner()),
          Expanded(
            child: Center(
              child: Text('Tap a zone on the map for details'),
            ),
          ),
        ],
      ),
    );
  }
}
