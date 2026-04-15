/// Venue map view with GroundOverlay floor plan and UWB blue dot.
///
/// Uses Google Maps as the base layer with:
/// - [GroundOverlay] for the stadium floor plan image (not GPS indoor maps)
/// - Manual "blue dot" placement using UWB data from [UserContext]
/// - [CrowdHeatmapLayer] as a custom tile overlay
/// - [FlowVectorLayer] for animated directional arrows
/// - Zone tap detection for opening [ZoneDetailSheet]
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../accessibility/wcag_tokens.dart';
import '../../providers/intent_providers.dart';
import '../zone/zone_detail_sheet.dart';
import 'crowd_heatmap_layer.dart';
import 'flow_vector_layer.dart';

/// Default venue center — replace with actual venue coordinates.
const _venueCenter = LatLng(37.4028, -121.9700); // e.g. Levi's Stadium
const _defaultZoom = 17.0;

class VenueMapView extends ConsumerStatefulWidget {
  const VenueMapView({super.key});

  @override
  ConsumerState<VenueMapView> createState() => _VenueMapViewState();
}

class _VenueMapViewState extends ConsumerState<VenueMapView> {
  GoogleMapController? _mapController;
  final _heatmapKey = GlobalKey();

  // Ground overlay for the floor plan image
  Set<GroundOverlay> get _groundOverlays => {
        GroundOverlay(
          groundOverlayId: const GroundOverlayId('floor_plan'),
          bounds: LatLngBounds(
            southwest: const LatLng(37.4020, -121.9710),
            northeast: const LatLng(37.4036, -121.9690),
          ),
          // In production: load from assets/floor_plans/
          // transparency: 0.1,
          // IMPORTANT: GroundOverlay requires a BitmapDescriptor.
          // The actual floor plan image must be provided at runtime.
          bitmap: BitmapDescriptor.defaultMarker, // placeholder
        ),
      };

  // Zone polygons for tap detection
  Set<Polygon> get _zonePolygons => {
        _buildZonePolygon(
          id: 'gate_c_concourse',
          points: const [
            LatLng(37.4025, -121.9705),
            LatLng(37.4025, -121.9695),
            LatLng(37.4030, -121.9695),
            LatLng(37.4030, -121.9705),
          ],
        ),
        // Add more zones as needed
      };

  Polygon _buildZonePolygon({
    required String id,
    required List<LatLng> points,
  }) {
    return Polygon(
      polygonId: PolygonId(id),
      points: points,
      fillColor: Colors.transparent,
      strokeColor: AvenuColors.accentBlue.withValues(alpha: 0.5),
      strokeWidth: 2,
      consumeTapEvents: true,
      onTap: () => _onZoneTapped(id),
    );
  }

  void _onZoneTapped(String zoneId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ZoneDetailSheet(zoneId: zoneId),
    );
  }

  /// Build a marker for the user's UWB position ("blue dot").
  Set<Marker> _buildUwbMarker() {
    final userCtx = ref.read(userContextProvider);
    // In production, convert UWB coordinates to LatLng
    // For now, place near venue center as demonstration
    if (userCtx.uwbProximityToGateM == null) return {};

    return {
      Marker(
        markerId: const MarkerId('uwb_position'),
        position: _venueCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'You are here'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base map with ground overlay
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _venueCenter,
            zoom: _defaultZoom,
          ),
          onMapCreated: (controller) => _mapController = controller,
          groundOverlays: _groundOverlays,
          polygons: _zonePolygons,
          markers: _buildUwbMarker(),
          mapType: MapType.normal,
          myLocationEnabled: false, // We use UWB, not GPS
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          // Dark map style applied via JSON (set in onMapCreated)
        ),

        // Crowd heatmap overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CrowdHeatmapLayer(key: _heatmapKey),
          ),
        ),

        // Flow vector animation overlay
        const Positioned.fill(
          child: IgnorePointer(
            child: FlowVectorLayer(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
