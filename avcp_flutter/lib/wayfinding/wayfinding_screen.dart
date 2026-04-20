import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';
import 'gate_intent_service.dart';
import 'kpi_strip.dart';
import 'direction_banner.dart';
import 'route_painter.dart';
import 'heatmap_tile_provider.dart';

class WayfindingScreen extends ConsumerStatefulWidget {
  const WayfindingScreen({
    super.key,
    required this.zoneId,
    required this.venueCenter,
  });

  final String zoneId;
  final LatLng venueCenter;

  @override
  ConsumerState<WayfindingScreen> createState() => _WayfindingScreenState();
}

class _WayfindingScreenState extends ConsumerState<WayfindingScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Currently relying on Mock Data Provider for UI deterministic loops
    final intent = GateIntentServiceImpl().detect(const GateContext(
        uwbProximityMeters: 280, bottleneckScore: 0, dwellRatio: 0, speedP95: 1.2, 
        densityPpm2: 0, zoneId: "C", assignedGateId: "C", alternateGateId: "D", 
        waitMinutes: 4, altWaitMinutes: 0, savingsMinutes: 0, seatSection: "114", 
        streetName: "Occidental Ave S", landmarkName: "WaMu Theater", distanceToTurnMeters: 280, ticketToken: "AVCP"
      ));

    final bool isNearGate = intent == WayfindingIntent.nearGate;
    final ext = Theme.of(context).extension<StadiumThemeExtension>()!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ext.tokens.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // [0] VenueMapBase
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.venueCenter,
              initialZoom: isNearGate ? 19.0 : 17.0,
              minZoom: 14.0,
              maxZoom: 20.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.avcp.dashboard',
                tileBuilder: (context, widget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -1,  0,  0, 0, 255,
                       0, -1,  0, 0, 255,
                       0,  0, -1, 0, 255,
                       0,  0,  0, 1,   0,
                    ]),
                    child: widget,
                  );
                },
              ),
              IgnorePointer(
                child: TileLayer(
                  tileProvider: HeatmapTileProvider(),
                ),
              ),
            ],
          ),

          // [2] RouteLayer
          IgnorePointer(
            child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: RoutePainter(
                routePoints: [
                  Offset(size.width * 0.5, size.height * 0.7),
                  Offset(size.width * 0.5, size.height * 0.4),
                  Offset(size.width * 0.6, size.height * 0.2),
                ],
                blockedPoints: intent == WayfindingIntent.rerouting ? [
                  Offset(size.width * 0.5, size.height * 0.4),
                  Offset(size.width * 0.4, size.height * 0.2),
                ] : [],
                gates: [
                  GatePinData(offset: Offset(size.width * 0.6, size.height * 0.2), gateId: 'C', state: intent == WayfindingIntent.rerouting ? 'blocked' : 'assigned'),
                  if (intent == WayfindingIntent.rerouting) GatePinData(offset: Offset(size.width * 0.8, size.height * 0.3), gateId: 'D', state: 'alternate'),
                ],
                tokens: ext.tokens,
                intent: intent,
                dashOffset: 0.0,
              ),
            ),
          ),
          ),

          // [3] StatusBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 44,
            child: Container(color: const Color(0xF20F1117)),
          ),

          // [4] KpiStrip
          Positioned(
            top: 44,
            left: 0,
            right: 0,
            child: KpiStrip(zoneId: widget.zoneId),
          ),

          // [5] Zoom Buttons
          Positioned(
            right: 12,
            bottom: size.height * 0.32 + 16,
            child: _ZoomButtonColumn(mapController: _mapController),
          ),

          // [6] DirectionBanner inside DraggableScrollableSheet
          DraggableScrollableSheet(
            minChildSize: 0.28,
            initialChildSize: 0.32,
            maxChildSize: 0.72,
            snap: true,
            snapSizes: const [0.32, 0.55, 0.72],
            builder: (context, scrollController) {
              return DirectionBanner(scrollController: scrollController);
            },
          ),
        ],
      ),
    );
  }
}

class _ZoomButtonColumn extends StatelessWidget {
  const _ZoomButtonColumn({required this.mapController});
  final MapController mapController;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ZoomButton(
        icon: Icons.add,
        onTap: () => mapController.move(mapController.camera.center, mapController.camera.zoom + 1),
      ),
      const SizedBox(height: 6),
      _ZoomButton(
        icon: Icons.remove,
        onTap: () => mapController.move(mapController.camera.center, mapController.camera.zoom - 1),
      ),
    ],
  );
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
      ),
      child: Icon(icon, color: const Color(0xFFFFD700), size: 20),
    ),
  );
}
