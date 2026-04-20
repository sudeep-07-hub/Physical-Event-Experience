import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import 'gate_intent_service.dart';
import '../providers.dart';

class DirectionBanner extends ConsumerWidget {
  const DirectionBanner({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GateContext ctx = ref.watch(mockGateContextProvider).value ?? const GateContext(
        uwbProximityMeters: 280, bottleneckScore: 0, dwellRatio: 0, speedP95: 1.2, 
        densityPpm2: 0, zoneId: "C", assignedGateId: "C", alternateGateId: "D", 
        waitMinutes: 4, altWaitMinutes: 0, savingsMinutes: 0, seatSection: "114", 
        streetName: "Occidental Ave S", landmarkName: "WaMu Theater", distanceToTurnMeters: 280, ticketToken: "AVCP"
      );
      
    final intentService = GateIntentServiceImpl();
    final intent = intentService.detect(ctx);

    final bool disableAnimations = MediaQuery.of(context).disableAnimations;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13161F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0x26FFD700), width: 1)),
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildBannerForIntent(intent, ctx),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildBannerForIntent(WayfindingIntent intent, GateContext ctx) {
    switch (intent) {
      case WayfindingIntent.freeFlowing:
        return _FreeFlowingBanner(key: const ValueKey(WayfindingIntent.freeFlowing), ctx: ctx);
      case WayfindingIntent.rerouting:
        return _ReroutingBanner(key: const ValueKey(WayfindingIntent.rerouting), ctx: ctx);
      case WayfindingIntent.nearGate:
        return _NearGateBanner(key: const ValueKey(WayfindingIntent.nearGate), ctx: ctx);
      case WayfindingIntent.waitTime:
        return _WaitTimeBanner(key: const ValueKey(WayfindingIntent.waitTime), ctx: ctx);
    }
  }
}

class _FreeFlowingBanner extends StatelessWidget {
  const _FreeFlowingBanner({super.key, required this.ctx});
  final GateContext ctx;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<StadiumThemeExtension>()!;
    return Semantics(
      label: 'Head north on ${ctx.streetName}. Clear path. Gate ${ctx.assignedGateId} in ${ctx.waitMinutes} minutes.',
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2B1A),
              border: Border.all(color: const Color(0x4000E676)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Head north on ${ctx.streetName}', style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF00E676))),
                      const SizedBox(height: 4),
                      Text('Clear path · Gate ${ctx.assignedGateId} in ${ctx.waitMinutes} min', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xB34CAF50))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(Icons.arrow_upward, color: ext.tokens.primaryGold, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Turn left at ${ctx.landmarkName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('Continue past ${ctx.landmarkName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF666666))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${ctx.distanceToTurnMeters}', style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFFFD700))),
                    const Text('m', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF666666))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ext.tokens.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {},
              child: Text('Navigate to Gate ${ctx.assignedGateId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.28)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReroutingBanner extends StatelessWidget {
  const _ReroutingBanner({super.key, required this.ctx});
  final GateContext ctx;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<StadiumThemeExtension>()!;
    return Semantics(
      label: 'Gate ${ctx.assignedGateId} is blocked. ${ctx.waitMinutes} min queue. Gate ${ctx.alternateGateId} is ${ctx.altWaitMinutes} min clear.',
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2B0D0D),
              border: Border.all(color: const Color(0x4DFF5252)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gate ${ctx.assignedGateId} is blocked', style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFF5252))),
                      const SizedBox(height: 4),
                      Text('${ctx.waitMinutes} min queue · Gate ${ctx.alternateGateId} is ${ctx.altWaitMinutes} min clear', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xB3FFFFFF))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Transform.rotate(
                    angle: 0.785398, // 45 degrees
                    child: Icon(Icons.arrow_upward, color: ext.tokens.success, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Turn right on ${ctx.streetName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('Gate ${ctx.alternateGateId} — your ticket is valid here', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF666666))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${ctx.distanceToTurnMeters}', style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF00E676))),
                    const Text('m', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF666666))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ext.tokens.success,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {},
              child: Text('Take faster route · Save ${ctx.savingsMinutes} min', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.28)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearGateBanner extends StatelessWidget {
  const _NearGateBanner({super.key, required this.ctx});
  final GateContext ctx;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<StadiumThemeExtension>()!;
    return Semantics(
      label: 'Gate ${ctx.assignedGateId}. Scan to enter. Section ${ctx.seatSection}.',
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1500),
              border: Border.all(color: const Color(0x59FFD700)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gate ${ctx.assignedGateId} · Scan to enter', style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFFD700))),
                      const SizedBox(height: 4),
                      Text('Section ${ctx.seatSection}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xB3FFFFFF))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: ctx.ticketToken,
                  size: 120,
                ),
                Text(ctx.ticketToken, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF666666))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ext.tokens.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {},
              child: const Text('Open turnstile · Hold to scanner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.28)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitTimeBanner extends StatelessWidget {
  const _WaitTimeBanner({super.key, required this.ctx});
  final GateContext ctx;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<StadiumThemeExtension>()!;
    return Semantics(
      label: 'Expect a ${ctx.waitMinutes} min wait at Gate ${ctx.assignedGateId}. Crowd is easing. Check back in 2 min.',
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1100),
              border: Border.all(color: const Color(0x4DFF9800)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expect a ${ctx.waitMinutes} min wait at Gate ${ctx.assignedGateId}', style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.orange)),
                      const SizedBox(height: 4),
                      Text('Crowd is easing · Check back in 2 min', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xB3FFFFFF))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(Icons.arrow_upward, color: ext.tokens.primaryGold, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Turn left at ${ctx.landmarkName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('Continue past ${ctx.landmarkName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF666666))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${ctx.distanceToTurnMeters}', style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFFFD700))),
                    const Text('m', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF666666))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {},
              child: Text('I\'ll wait · Continue to Gate ${ctx.assignedGateId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.28)),
            ),
          ),
        ],
      ),
    );
  }
}
