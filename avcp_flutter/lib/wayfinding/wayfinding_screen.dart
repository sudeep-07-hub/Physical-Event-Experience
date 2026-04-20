import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers.dart';
import '../theme.dart';
import 'gate_intent_service.dart';
import 'kpi_strip.dart';
import 'direction_banner.dart';

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
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
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
          // [0] VenueMapBase (GoogleMap Integration)
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.venueCenter,
              zoom: isNearGate ? 19.0 : 17.0,
            ),
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            style: _googleMapDarkStyle,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              ref.read(mapZoomProvider.notifier).state = position.zoom;
            },
            polylines: ref.watch(routePolylinesProvider(widget.zoneId)),
            markers: ref.watch(routeMarkersProvider(widget.zoneId)),
          ),

          // [2] RouteLayer (DELETED: Now handled by native polylines/markers)


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
  final GoogleMapController? mapController;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ZoomButton(
        icon: Icons.add,
        onTap: () async {
          if (mapController == null) return;
          final zoom = await mapController!.getZoomLevel();
          mapController!.animateCamera(CameraUpdate.zoomTo(zoom + 1));
        },
      ),
      const SizedBox(height: 6),
      _ZoomButton(
        icon: Icons.remove,
        onTap: () async {
          if (mapController == null) return;
          final zoom = await mapController!.getZoomLevel();
          mapController!.animateCamera(CameraUpdate.zoomTo(zoom - 1));
        },
      ),
    ],
  );
}

// Dark standard map style JSON
const String _googleMapDarkStyle = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#212121" } ] },
  { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
  { "elementType": "labels.text.fill", "stylers": [ { "color": "#757575" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#212121" } ] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [ { "color": "#757575" } ] },
  { "featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [ { "color": "#9e9e9e" } ] },
  { "featureType": "landscape", "elementType": "geometry", "stylers": [ { "color": "#121212" } ] },
  { "featureType": "poi", "elementType": "geometry", "stylers": [ { "color": "#121212" } ] },
  { "featureType": "road", "elementType": "geometry.fill", "stylers": [ { "color": "#2c2c2c" } ] },
  { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#8a8a8a" } ] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#3c3c3c" } ] },
  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#000000" } ] }
]
''';

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
