import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers.dart';
import 'gate_intent_service.dart';

class KpiStrip extends ConsumerWidget {
  const KpiStrip({super.key, required this.zoneId});
  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = Theme.of(context).extension<StadiumThemeExtension>()!;
    
    return Container(
      height: 52,
      color: ext.tokens.kpiOverlay,
      decoration: BoxDecoration(
        color: ext.tokens.kpiOverlay,
        border: const Border(
          bottom: BorderSide(color: Color(0x0FFFFFFF), width: 1.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(child: _FlowCard(zoneId: zoneId)),
            Expanded(child: _GateTimeCard(zoneId: zoneId)),
            Expanded(child: _ContextCard(zoneId: zoneId)),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.semanticsLabel,
  });

  final String label;
  final String value;
  final Color color;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 52,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ).copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowCard extends ConsumerWidget {
  const _FlowCard({required this.zoneId});
  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = Theme.of(context).extension<StadiumThemeExtension>()!;
    final double speed = ref.watch(
      crowdVectorProvider(zoneId).select((v) => v.value?.speedP95 ?? 0.0),
    );

    Color dotColor = ext.tokens.alertRed;
    if (speed > 0.8) {
      dotColor = ext.tokens.success;
    } else if (speed > 0.3) {
      dotColor = ext.tokens.primaryGold;
    }

    final String display = speed.toStringAsFixed(1);
    return _KpiCard(
      label: 'm/s flow',
      value: '$display m/s',
      color: dotColor,
      semanticsLabel: 'Flow speed: $display metres per second',
    );
  }
}

class _GateTimeCard extends ConsumerWidget {
  const _GateTimeCard({required this.zoneId});
  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = Theme.of(context).extension<StadiumThemeExtension>()!;
    // Using fake ticket/gate context for now since provider integration depends on app state
    final GateContext ctx = ref.watch(mockGateContextProvider).value ?? const GateContext(
          uwbProximityMeters: 280, bottleneckScore: 0, dwellRatio: 0, speedP95: 1.2, 
          densityPpm2: 0, zoneId: "C", assignedGateId: "C", alternateGateId: "D", 
          waitMinutes: 4, altWaitMinutes: 0, savingsMinutes: 0, seatSection: "114", 
          streetName: "", landmarkName: "", distanceToTurnMeters: 0, ticketToken: "AVCP"
        );
        
    final IntentService = GateIntentServiceImpl();
    final intent = IntentService.detect(ctx);

    final double ratio = ref.watch(
      crowdVectorProvider(zoneId).select((v) => v.value?.dwellRatio ?? 0.0),
    );
    final int minutes = (ratio * 15).round();

    Color dotColor = ext.tokens.alertRed;
    if (minutes < 5) dotColor = ext.tokens.success;
    else if (minutes < 10) dotColor = ext.tokens.primaryGold;

    String display = '$minutes min to Gate ${ctx.assignedGateId}';
    if (intent == WayfindingIntent.rerouting) {
      display = '$minutes min Gate ${ctx.assignedGateId} wait';
    } else if (intent == WayfindingIntent.nearGate) {
      display = '${ctx.uwbProximityMeters.round()}m to Gate ${ctx.assignedGateId}';
    }

    return _KpiCard(
      label: 'wait time',
      value: display,
      color: dotColor,
      semanticsLabel: 'Estimated wait: $minutes minutes',
    );
  }
}

class _ContextCard extends ConsumerWidget {
  const _ContextCard({required this.zoneId});
  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = Theme.of(context).extension<StadiumThemeExtension>()!;
    final GateContext ctx = ref.watch(mockGateContextProvider).value ?? const GateContext(
          uwbProximityMeters: 280, bottleneckScore: 0, dwellRatio: 0, speedP95: 1.2, 
          densityPpm2: 0, zoneId: "C", assignedGateId: "C", alternateGateId: "D", 
          waitMinutes: 4, altWaitMinutes: 0, savingsMinutes: 0, seatSection: "114", 
          streetName: "", landmarkName: "", distanceToTurnMeters: 0, ticketToken: "AVCP"
        );
        
    final IntentService = GateIntentServiceImpl();
    final intent = IntentService.detect(ctx);
    
    final double density = ref.watch(
      crowdVectorProvider(zoneId).select((v) => v.value?.densityPpm2 ?? 0.0),
    );

    String display = '${((density / 6.5) * 100).round()}% density';
    Color dotColor = ext.tokens.uwbBlue;

    if (intent == WayfindingIntent.nearGate) {
      display = 'Sec ${ctx.seatSection}';
      dotColor = ext.tokens.primaryGold;
    } else if (intent == WayfindingIntent.rerouting) {
      display = 'Save ${ctx.savingsMinutes} min';
      dotColor = ext.tokens.success;
    } else if (intent == WayfindingIntent.waitTime) {
      display = '~${ctx.altWaitMinutes} min alt';
      dotColor = Colors.orange;
    }

    return _KpiCard(
      label: 'context',
      value: display,
      color: dotColor,
      semanticsLabel: 'Context details: $display',
    );
  }
}
