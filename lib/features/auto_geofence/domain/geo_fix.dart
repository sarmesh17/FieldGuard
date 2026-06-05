/// A single location fix reduced to what geofence detection needs.
///
/// [timestampUtc] is wall-clock UTC — never a monotonic / Stopwatch value.
/// Durations are derived by subtracting persisted UTC timestamps, so they
/// remain correct across process death (a monotonic clock resets on
/// restart and would break recovery).
class GeoFix {
  final double latitude;
  final double longitude;

  /// Reported horizontal accuracy radius in metres. Smaller is better.
  final double accuracyMeters;

  final DateTime timestampUtc;

  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestampUtc,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
    'timestampUtc': timestampUtc.toUtc().toIso8601String(),
  };

  factory GeoFix.fromJson(Map<String, dynamic> json) => GeoFix(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
    timestampUtc: DateTime.parse(json['timestampUtc'] as String).toUtc(),
  );
}
