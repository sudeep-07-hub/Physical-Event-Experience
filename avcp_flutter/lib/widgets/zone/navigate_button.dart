/// Navigate button — triggers wayfinding provider.
///
/// Minimum 44×44pt touch target per WCAG 2.5.5.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessibility/wcag_tokens.dart';
import '../../models/wayfinding_request.dart';
import '../../providers/intent_providers.dart';

class NavigateButton extends ConsumerWidget {
  const NavigateButton({
    super.key,
    required this.fromZoneId,
    this.toZoneId,
    this.label = 'Navigate',
  });

  final String fromZoneId;
  final String? toZoneId;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: '$label from $fromZoneId',
      child: SizedBox(
        height: AvenuTouchTargets.recommended,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _onNavigate(context, ref),
          icon: const Icon(Icons.navigation_rounded),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: AvenuColors.accentBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _onNavigate(BuildContext context, WidgetRef ref) {
    final target = toZoneId;
    if (target == null) {
      // TODO: open zone picker
      return;
    }

    final request = WayfindingRequest(
      fromZoneId: fromZoneId,
      toZoneId: target,
    );

    // Trigger the wayfinding provider — result will be consumed
    // by the route overlay on the map.
    ref.read(wayfindingProvider(request));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Computing route to $target...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
