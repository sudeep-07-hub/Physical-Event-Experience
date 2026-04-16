/// AVCP Contextual Action Banner — Triple-Threat UI v1.0.0
///
/// AnimatedSwitcher-driven banner that surfaces the correct action
/// based on [intentProvider]:
///   - [_TicketQrBanner] for ticketQr intent
///   - [_WaitTimeBanner] for waitTime intent
///   - [_ReroutingBanner] for rerouting intent
///   - [SizedBox.shrink] for none
///
/// All banners auto-dismiss after 8s. All timers cancelled in dispose().
/// All buttons meet 44×44pt WCAG touch target minimum.
/// Zero PII — only zone_id and anonymous float signals.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:avcp_flutter/intent_service.dart';
import 'package:avcp_flutter/theme.dart';
import 'package:avcp_flutter/providers.dart';

// ══════════════════════════════════════════════════════════════════════
// Root Banner Widget
// ══════════════════════════════════════════════════════════════════════

/// Contextual action banner driven by [intentProvider].
///
/// Uses [AnimatedSwitcher] with fade + slide transition.
/// Each child carries a [ValueKey<UserIntent>] for proper animation.
class ContextualActionBanner extends ConsumerWidget {
  const ContextualActionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserIntent intent = ref.watch(intentProvider);
    final UserContext ctx = ref.watch(userContextDataProvider);
    final bool disableAnimations =
        MediaQuery.of(context).disableAnimations;

    return AnimatedSwitcher(
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 350),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildBannerForIntent(intent, ctx),
    );
  }

  Widget _buildBannerForIntent(UserIntent intent, UserContext ctx) {
    switch (intent) {
      case UserIntent.ticketQr:
        return _TicketQrBanner(
          key: const ValueKey<UserIntent>(UserIntent.ticketQr),
          gateId: ctx.assignedGateId,
        );
      case UserIntent.waitTime:
        return _WaitTimeBanner(
          key: const ValueKey<UserIntent>(UserIntent.waitTime),
          waitMinutes: ctx.waitMinutes,
          zoneId: ctx.zoneId,
        );
      case UserIntent.rerouting:
        return _ReroutingBanner(
          key: const ValueKey<UserIntent>(UserIntent.rerouting),
          savingsMinutes: (ctx.waitMinutes * 0.6).round().clamp(1, 15),
        );
      case UserIntent.none:
        return SizedBox.shrink(
          key: const ValueKey<UserIntent>(UserIntent.none),
        );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════
// Ticket QR Banner
// ══════════════════════════════════════════════════════════════════════

class _TicketQrBanner extends StatefulWidget {
  const _TicketQrBanner({super.key, required this.gateId});

  final String gateId;

  @override
  State<_TicketQrBanner> createState() => _TicketQrBannerState();
}

class _TicketQrBannerState extends State<_TicketQrBanner> {
  Timer? _dismissTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(seconds: 8), _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink(
        key: ValueKey<String>('ticket_dismissed'),
      );
    }

    final StadiumThemeExtension ext =
        Theme.of(context).extension<StadiumThemeExtension>()!;

    return Semantics(
      label: 'Ticket QR for gate ${widget.gateId}. Scan to enter.',
      child: GestureDetector(
        onTap: () {
          _dismissTimer?.cancel();
          _dismiss();
        },
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ext.tokens.surface,
            border: Border.all(
              color: ext.tokens.primaryGold,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: <Widget>[
              // QR Code
              QrImageView(
                data: 'AVCP_GATE_${widget.gateId}_${DateTime.now().millisecondsSinceEpoch}',
                version: QrVersions.auto,
                size: 100,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),

              const SizedBox(width: 16),

              // Gate info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Gate ${widget.gateId}',
                      style: AvenuTypography.kpi(context).copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan to enter',
                      style: AvenuTypography.label(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Auto-dismiss in 8s · Tap to close',
                      style: AvenuTypography.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Wait Time Banner
// ══════════════════════════════════════════════════════════════════════

class _WaitTimeBanner extends StatefulWidget {
  const _WaitTimeBanner({
    super.key,
    required this.waitMinutes,
    required this.zoneId,
  });

  final int waitMinutes;
  final String zoneId;

  @override
  State<_WaitTimeBanner> createState() => _WaitTimeBannerState();
}

class _WaitTimeBannerState extends State<_WaitTimeBanner> {
  Timer? _dismissTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(seconds: 8), _dismiss);
  }

  @override
  void didUpdateWidget(covariant _WaitTimeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset timer on new intent arrival
    if (oldWidget.waitMinutes != widget.waitMinutes) {
      _dismissTimer?.cancel();
      _visible = true;
      _dismissTimer = Timer(const Duration(seconds: 8), _dismiss);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final StadiumThemeExtension ext =
        Theme.of(context).extension<StadiumThemeExtension>()!;

    return Semantics(
      label: 'Wait time: ${widget.waitMinutes} minutes. '
          'Gate ${widget.zoneId} congested. Alternate route available.',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ext.tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ext.tokens.alertRed.withAlpha(128)),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.timer_outlined,
              color: ext.tokens.alertRed,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${widget.waitMinutes} min wait',
                    style: AvenuTypography.label(context).copyWith(
                      color: ext.tokens.alertRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gate ${widget.zoneId} congested',
                    style: AvenuTypography.caption(context),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: () {
                  // Would trigger rerouting flow
                  _dismissTimer?.cancel();
                  _dismiss();
                },
                child: Text(
                  'Try alternate route →',
                  style: AvenuTypography.label(context).copyWith(
                    color: ext.tokens.primaryGold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Rerouting Banner
// ══════════════════════════════════════════════════════════════════════

class _ReroutingBanner extends StatefulWidget {
  const _ReroutingBanner({
    super.key,
    required this.savingsMinutes,
  });

  final int savingsMinutes;

  @override
  State<_ReroutingBanner> createState() => _ReroutingBannerState();
}

class _ReroutingBannerState extends State<_ReroutingBanner>
    with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  bool _visible = true;
  late final AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _dismissTimer = Timer(const Duration(seconds: 8), _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _arrowController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) setState(() => _visible = false);
  }

  void _onNavigateTap() {
    _dismissTimer?.cancel();
    // In production: launch wayfinding navigation
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final StadiumThemeExtension ext =
        Theme.of(context).extension<StadiumThemeExtension>()!;

    return Semantics(
      label: 'Faster route found. ${widget.savingsMinutes} minutes less. '
          'Tap Navigate to start.',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ext.tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ext.tokens.success.withAlpha(128)),
        ),
        child: Row(
          children: <Widget>[
            // Animated rotating arrow
            RotationTransition(
              turns: _arrowController,
              child: Icon(
                Icons.navigation_rounded,
                color: ext.tokens.success,
                size: 32,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Faster route found',
                    style: AvenuTypography.label(context).copyWith(
                      color: ext.tokens.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.savingsMinutes} min less',
                    style: AvenuTypography.caption(context),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 44,
              width: 100,
              child: ElevatedButton(
                onPressed: _onNavigateTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ext.tokens.primaryGold,
                  foregroundColor: ext.tokens.onPrimary,
                ),
                child: const Text('Navigate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
