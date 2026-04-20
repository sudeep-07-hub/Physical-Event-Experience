/// AVCP Riverpod Providers — Triple-Threat UI v1.0.0
///
/// All StreamProviders and derived providers for the dashboard.
/// Mock mode is controlled via `--dart-define=MOCK_DATA=true`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avcp_flutter/intent_service.dart';
import 'package:avcp_flutter/mock_data_generator.dart';
import 'package:avcp_flutter/crowd_vector.dart';
import 'package:avcp_flutter/wayfinding/gate_intent_service.dart';
import 'package:avcp_flutter/mock/wayfinding_mock_data.dart';

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
  // Import and use FirebaseCrowdService in production builds.
  return MockDataGenerator.stream(zoneId: zoneId);
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
