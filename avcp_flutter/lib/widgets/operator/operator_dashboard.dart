/// Operator dashboard — staff-only, role-gated view.
///
/// Only visible when [UserContext.role] is [UserRole.operator].
/// Contains: KPI row, alert queue, and manual override panel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessibility/wcag_tokens.dart';
import '../../models/user_context.dart';
import '../../providers/intent_providers.dart';
import 'alert_queue.dart';
import 'manual_override_panel.dart';
import 'venue_health_kpi_row.dart';

class OperatorDashboard extends ConsumerWidget {
  const OperatorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userContext = ref.watch(userContextProvider);

    // Role gate — only operators see this
    if (userContext.role != UserRole.operator) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: AvenuColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'Operator access required',
              style: TextStyle(color: AvenuColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AvenuColors.surfaceDark,
      child: const SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Operator Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AvenuColors.textPrimary,
                ),
              ),
            ),
            Divider(color: AvenuColors.surfaceCard),

            // KPI row
            VenueHealthKpiRow(),

            SizedBox(height: 8),
            Divider(color: AvenuColors.surfaceCard),

            // Alert queue (scrollable, takes available space)
            Expanded(child: AlertQueue()),

            Divider(color: AvenuColors.surfaceCard),

            // Manual override panel (fixed at bottom)
            ManualOverridePanel(),
          ],
        ),
      ),
    );
  }
}
