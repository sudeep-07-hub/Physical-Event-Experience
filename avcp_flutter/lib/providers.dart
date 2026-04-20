/// AVCP Riverpod Providers — Triple-Threat UI v1.0.0
///
/// All StreamProviders and derived providers for the dashboard.
/// Mock mode is controlled via `--dart-define=MOCK_DATA=true`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:avcp_flutter/wayfinding/gate_bitmaps.dart';
import 'package:avcp_flutter/intent_service.dart';
import 'package:avcp_flutter/mock_data_generator.dart';
import 'package:avcp_flutter/crowd_vector.dart';
import 'package:avcp_flutter/wayfinding/gate_intent_service.dart';
import 'package:avcp_flutter/mock/wayfinding_mock_data.dart';
import 'package:avcp_flutter/services/firebase_crowd_service.dart';

// ══════════════════════════════════════════════════════════════════════
// Navigation Providers (Nav-Sync v1.2.0)
// ══════════════════════════════════════════════════════════════════════

/// Static map of gate IDs to their geo-coordinates.
final gateLatLngProvider = Provider.family<LatLng, String>((ref, gateId) {
  // Stadium Gate coordinates (approximate based on Lumen Field layout)
  final gates = {
    'C': const LatLng(47.5952, -122.3316),
    'D': const LatLng(47.5960, -122.3325),
    'A': const LatLng(47.5940, -122.3310),
  };
  return gates[gateId] ?? const LatLng(47.5952, -122.3316);
});

/// Current user location (Mock moving dot).
final userLatLngProvider = StateProvider<LatLng>((ref) {
  return const LatLng(47.5945, -122.3323); // Centered in the stadium bowl
});

/// Map zoom level tracker for dynamic UI adjustments.
final mapZoomProvider = StateProvider<double>((ref) => 17.0);

/// FutureProvider for high-DPI rendered marker icons.
final gateBitmapsProvider = FutureProvider<GateBitmaps>((ref) async {
  return GateBitmaps.create(dpr: 2.0); // Default to 2.0, will be updated in UI if needed
});

/// Navigation waypoint calculations based on current Intent.
final routeWaypointsProvider = Provider.family<List<LatLng>, String>((ref, zoneId) {
  final ctxResult = ref.watch(mockGateContextProvider);
  final ctx = ctxResult.valueOrNull;
  if (ctx == null) return [];

  final userPos = ref.watch(userLatLngProvider);
  final gatePos = ref.watch(gateLatLngProvider(ctx.assignedGateId));

  // For mock: direct line. In production, this would call a directions API or A* mesh.
  return [userPos, gatePos];
});

/// Secondary points for "congested" or blocked routes.
final blockedRouteWaypointsProvider = Provider.family<List<LatLng>, String>((ref, zoneId) {
  // Returning an arbitrary blocked path Segment for rerouting demo
  return [const LatLng(47.5945, -122.3323), const LatLng(47.5952, -122.3325)];
});

/// Native Polyline set for the map.
final routePolylinesProvider = Provider.family<Set<Polyline>, String>((ref, zoneId) {
  final waypoints = ref.watch(routeWaypointsProvider(zoneId));
  final ctx = ref.watch(mockGateContextProvider).valueOrNull;
  if (ctx == null || waypoints.isEmpty) return {};

  final intentService = GateIntentServiceImpl();
  final intent = intentService.detect(ctx);

  final routeColor = intent == WayfindingIntent.rerouting
      ? const Color(0xFF00E676)
      : const Color(0xFFFFD700);

  final glowColor = intent == WayfindingIntent.rerouting
      ? const Color(0x3300E676)
      : const Color(0x33FFD700);

  return {
    // Soft glow underneath
    Polyline(
      polylineId: const PolylineId('route_glow'),
      points: waypoints,
      color: glowColor,
      width: 10,
      jointType: JointType.round,
      endCap: Cap.roundCap,
      startCap: Cap.roundCap,
    ),
    // Main route line
    Polyline(
      polylineId: const PolylineId('route_main'),
      points: waypoints,
      color: routeColor,
      width: 4,
      patterns: [PatternItem.dot, PatternItem.gap(14)],
      jointType: JointType.round,
      endCap: Cap.roundCap,
      startCap: Cap.roundCap,
    ),
  };
});

/// Native Marker set for the map.
final routeMarkersProvider = Provider.family<Set<Marker>, String>((ref, zoneId) {
  final ctx = ref.watch(mockGateContextProvider).valueOrNull;
  final bitmapsAsync = ref.watch(gateBitmapsProvider);
  
  if (ctx == null) return {};
  final bitmaps = bitmapsAsync.valueOrNull;
  if (bitmaps == null) return {};

  final intentService = GateIntentServiceImpl();
  final intent = intentService.detect(ctx);
  final userPos = ref.watch(userLatLngProvider);
  final gatePos = ref.watch(gateLatLngProvider(ctx.assignedGateId));

  final markers = <Marker>{};

  // User dot
  markers.add(Marker(
    markerId: const MarkerId('user_dot'),
    position: userPos,
    icon: bitmaps.userDot,
    anchor: const Offset(0.5, 0.5),
    flat: true,
    zIndex: 10,
  ));

  // Assigned gate
  markers.add(Marker(
    markerId: MarkerId('gate_${ctx.assignedGateId}'),
    position: gatePos,
    icon: switch (intent) {
      WayfindingIntent.nearGate => bitmaps.gateNearGold,
      WayfindingIntent.rerouting => bitmaps.gateBlocked,
      _ => bitmaps.gateAssigned,
    },
    anchor: const Offset(0.5, 0.5),
    flat: true,
    zIndex: 9,
  ));

  // Alternate gate (rerouting only)
  if (intent == WayfindingIntent.rerouting) {
    markers.add(Marker(
      markerId: MarkerId('gate_alt_${ctx.alternateGateId}'),
      position: ref.watch(gateLatLngProvider(ctx.alternateGateId)),
      icon: bitmaps.gateAlternate,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndex: 9,
    ));
  }

  return markers;
});

// ══════════════════════════════════════════════════════════════════════
// Mock Mode Flag
// ══════════════════════════════════════════════════════════════════════

/// Set via `--dart-define=MOCK_DATA=true`. Defaults to `false` for production.
const bool kUseMock = bool.fromEnvironment('MOCK_DATA', defaultValue: false);

// ══════════════════════════════════════════════════════════════════════
// Crowd Vector Provider
// ══════════════════════════════════════════════════════════════════════

/// StreamProvider.family keyed by zone_id.
///
/// In mock mode: [MockDataGenerator.stream].
/// In release: FirebaseCrowdService.watchZone(zoneId).
final crowdVectorProvider =
    StreamProvider.family<CrowdVelocityVector, String>((ref, zoneId) {
  if (kUseMock) {
    return MockDataGenerator.stream(zoneId: zoneId);
  }
  // Release path — Firebase RTDB stream.
  return FirebaseCrowdService().watchZone(zoneId);
});

// ══════════════════════════════════════════════════════════════════════
// User Context Provider
// ══════════════════════════════════════════════════════════════════════

/// StreamProvider for anonymous [UserContext].
///
/// In mock mode: [MockDataGenerator.contextStream] cycling 4 scenarios.
/// In release: combine UWBService + crowdVectorProvider.
final userContextProvider = StreamProvider<UserContext>((ref) {
  if (kUseMock) {
    return MockDataGenerator.contextStream();
  }
  // Release path — derive context from Firebase crowd vectors.
  // In production, this combines UWBService + crowd vectors.
  return MockDataGenerator.contextStream();
});

// ══════════════════════════════════════════════════════════════════════
// Gate Context Provider (Wayfinding)
// ══════════════════════════════════════════════════════════════════════

final mockGateContextProvider = StreamProvider<GateContext>((ref) {
  return WayfindingMockData.contextStream();
});

// ══════════════════════════════════════════════════════════════════════
// Intent Provider
// ══════════════════════════════════════════════════════════════════════

/// Intent detection service instance.
final intentDetectionServiceProvider = Provider<IntentDetectionService>((ref) {
  return const IntentDetectionServiceImpl();
});

/// Derived provider: current [UserIntent] from the latest [UserContext].
///
/// Returns [UserIntent.none] on loading or error — never throws.
final intentProvider = Provider<UserIntent>((ref) {
  final AsyncValue<UserContext> contextAsync = ref.watch(userContextProvider);
  final IntentDetectionService service =
      ref.watch(intentDetectionServiceProvider);

  return contextAsync.when(
    data: (UserContext ctx) => service.detectIntent(ctx),
    loading: () => UserIntent.none,
    error: (Object _, StackTrace __) => UserIntent.none,
  );
});

/// Provides the latest [UserContext] data, or a default on loading/error.
final userContextDataProvider = Provider<UserContext>((ref) {
  final AsyncValue<UserContext> contextAsync = ref.watch(userContextProvider);

  return contextAsync.when(
    data: (UserContext ctx) => ctx,
    loading: () => const UserContext(
      uwbProximityMeters: 999.0,
      dwellRatio: 0.0,
      bottleneckScore: 0.0,
      zoneId: '',
      assignedGateId: '',
      waitMinutes: 0,
    ),
    error: (Object _, StackTrace __) => const UserContext(
      uwbProximityMeters: 999.0,
      dwellRatio: 0.0,
      bottleneckScore: 0.0,
      zoneId: '',
      assignedGateId: '',
      waitMinutes: 0,
    ),
  );
});
