/// Barrel export for the AVCP Glanceable UI component system.
///
/// Import this single file to access all models, services, providers,
/// and widgets:
/// ```dart
/// import 'package:avcp_flutter/index.dart';
/// ```
library;

// ── Models ──────────────────────────────────────────────────────────────
export 'models/congestion_level.dart';
export 'models/crowd_velocity_vector.dart';
export 'models/indoor_route.dart';
export 'models/user_context.dart';
export 'models/user_intent.dart';
export 'models/wayfinding_request.dart';
export 'models/zone_alert.dart';

// ── Accessibility ───────────────────────────────────────────────────────
export 'accessibility/wcag_tokens.dart';

// ── Services (Layer 1 — Pure Dart) ──────────────────────────────────────
export 'services/crowd_analysis_service.dart';
export 'services/crowd_analysis_service_impl.dart';
export 'services/firebase_service.dart';
export 'services/intent_detection_service.dart';
export 'services/intent_detection_service_impl.dart';
export 'services/maps_service.dart';

// ── Providers (Layer 0 — Riverpod) ──────────────────────────────────────
export 'providers/crowd_state_provider.dart';
export 'providers/intent_providers.dart';
export 'providers/service_providers.dart';

// ── Theme ───────────────────────────────────────────────────────────────
export 'theme/avenu_theme.dart';

// ── Widgets (Layer 2) ───────────────────────────────────────────────────
export 'widgets/app/avenu_control_app.dart';
export 'widgets/banner/alternate_route_suggestion.dart';
export 'widgets/banner/contextual_action_banner.dart';
export 'widgets/banner/ticket_qr_surface.dart';
export 'widgets/banner/wait_time_banner.dart';
export 'widgets/map/crowd_heatmap_layer.dart';
export 'widgets/map/flow_vector_layer.dart';
export 'widgets/map/venue_map_view.dart';
export 'widgets/map/zone_tap_handler.dart';
export 'widgets/operator/alert_queue.dart';
export 'widgets/operator/manual_override_panel.dart';
export 'widgets/operator/operator_dashboard.dart';
export 'widgets/operator/venue_health_kpi_row.dart';
export 'widgets/scaffold/adaptive_scaffold.dart';
export 'widgets/zone/congestion_indicator.dart';
export 'widgets/zone/navigate_button.dart';
export 'widgets/zone/predictive_trend_chart.dart';
export 'widgets/zone/wait_time_estimate.dart';
export 'widgets/zone/zone_detail_sheet.dart';
