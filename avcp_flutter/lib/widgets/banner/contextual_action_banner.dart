/// Contextual action banner — intent-driven, auto-surfaces and auto-dismisses.
///
/// Driven by [IntentDetectionService] via [activeIntentProvider].
/// Surfaces the appropriate child widget based on the detected intent:
/// - [TicketQRSurface] when UWB proximity < 30m
/// - [WaitTimeBanner] when dwell_ratio > 0.6
/// - [AlternateRouteSuggestion] when bottleneck_score > 0.75
///
/// Auto-dismisses after 8 seconds or on user action.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessibility/wcag_tokens.dart';
import '../../models/user_intent.dart';
import '../../providers/intent_providers.dart';
import 'alternate_route_suggestion.dart';
import 'ticket_qr_surface.dart';
import 'wait_time_banner.dart';

/// Auto-dismiss duration.
const _autoDismissDuration = Duration(seconds: 8);

class ContextualActionBanner extends ConsumerStatefulWidget {
  const ContextualActionBanner({super.key});

  @override
  ConsumerState<ContextualActionBanner> createState() =>
      _ContextualActionBannerState();
}

class _ContextualActionBannerState
    extends ConsumerState<ContextualActionBanner> {
  Timer? _dismissTimer;
  bool _dismissed = false;
  UserIntent? _lastIntent;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_autoDismissDuration, () {
      if (mounted) {
        setState(() => _dismissed = true);
      }
    });
  }

  void _onDismiss() {
    _dismissTimer?.cancel();
    setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    final intent = ref.watch(activeIntentProvider);

    // Reset dismissed state when intent changes
    if (intent != _lastIntent) {
      _lastIntent = intent;
      _dismissed = false;
      if (intent is! IntentNone) {
        _startDismissTimer();
      }
    }

    // Don't show anything for IntentNone or if dismissed
    if (intent is IntentNone || _dismissed) {
      return const SizedBox.shrink();
    }

    final child = switch (intent) {
      IntentShowTicketQR(:final gateId, :final distanceMetres) =>
        TicketQRSurface(
          gateId: gateId,
          distanceMetres: distanceMetres,
        ),
      IntentShowWaitTime(
        :final zoneId,
        :final dwellRatio,
        :final estimatedWaitMinutes,
      ) =>
        WaitTimeBanner(
          zoneId: zoneId,
          dwellRatio: dwellRatio,
          estimatedWaitMinutes: estimatedWaitMinutes,
        ),
      IntentOfferAlternateRoute(
        :final fromZoneId,
        :final suggestedZoneId,
        :final bottleneckScore,
      ) =>
        AlternateRouteSuggestion(
          fromZoneId: fromZoneId,
          suggestedZoneId: suggestedZoneId,
          bottleneckScore: bottleneckScore,
        ),
      IntentNone() => const SizedBox.shrink(),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Dismissible(
          key: ValueKey(intent.runtimeType),
          direction: DismissDirection.up,
          onDismissed: (_) => _onDismiss(),
          child: Semantics(
            liveRegion: true, // Announce to screen readers when surfaced
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: AvenuColors.surfaceCard,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {}, // Absorb tap to prevent map interaction
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: child),
                      // Dismiss button — minimum 44x44 touch target
                      SizedBox(
                        width: AvenuTouchTargets.minimum,
                        height: AvenuTouchTargets.minimum,
                        child: IconButton(
                          onPressed: _onDismiss,
                          icon: const Icon(Icons.close),
                          tooltip: 'Dismiss',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
