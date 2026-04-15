/// Wayfinding request — input to [MapsService.computeRoute].
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'wayfinding_request.freezed.dart';
part 'wayfinding_request.g.dart';

@freezed
class WayfindingRequest with _$WayfindingRequest {
  const factory WayfindingRequest({
    @JsonKey(name: 'from_zone_id') required String fromZoneId,
    @JsonKey(name: 'to_zone_id') required String toZoneId,

    /// Zone IDs to avoid (e.g., congested zones).
    @JsonKey(name: 'avoid_zones') @Default([]) List<String> avoidZones,
  }) = _WayfindingRequest;

  factory WayfindingRequest.fromJson(Map<String, dynamic> json) =>
      _$WayfindingRequestFromJson(json);
}
