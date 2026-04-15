/// Alert queue — scrollable list of zone alerts, sorted by severity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessibility/wcag_tokens.dart';
import '../../models/zone_alert.dart';
import '../../providers/crowd_state_provider.dart';

class AlertQueue extends ConsumerWidget {
  const AlertQueue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AvenuColors.accentGreen,
                ),
                SizedBox(height: 8),
                Text(
                  'No active alerts',
                  style: TextStyle(color: AvenuColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: alerts.length,
          itemBuilder: (context, index) => _AlertTile(alert: alerts[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final ZoneAlert alert;

  @override
  Widget build(BuildContext context) {
    final severityColor = alert.severity.color;

    return Semantics(
      label: '${alert.severity.label} alert: ${alert.message}',
      child: Card(
        color: AvenuColors.surfaceCard,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: severityColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Severity icon
              Icon(
                alert.severity.icon,
                color: severityColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              // Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.alertType.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: severityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AvenuColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Acknowledge button
              if (!alert.acknowledged)
                SizedBox(
                  width: AvenuTouchTargets.minimum,
                  height: AvenuTouchTargets.minimum,
                  child: IconButton(
                    onPressed: () {
                      // TODO: acknowledge alert via provider
                    },
                    icon: const Icon(Icons.check, size: 20),
                    tooltip: 'Acknowledge alert',
                    color: AvenuColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
