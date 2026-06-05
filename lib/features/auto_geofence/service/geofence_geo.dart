import 'package:fieldguard/features/auto_geofence/config/geofence_config.dart';
import 'package:fieldguard/features/auto_geofence/domain/geo_fix.dart';
import 'package:geolocator/geolocator.dart';

/// Pure geometric / fix-quality helpers used by the geofence state machine.
class GeofenceGeo {
  const GeofenceGeo._();

  /// Great-circle distance in metres (delegates to geolocator's haversine).
  static double distanceMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) => Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

  /// A fix is usable for detection only when its accuracy radius is good
  /// enough; a noisy fix is neither enter nor exit evidence.
  static bool isAccurate(GeoFix fix) =>
      fix.accuracyMeters > 0 &&
      fix.accuracyMeters <= GeofenceConfig.maxAccuracyMeters;

  /// True if [fix] is too far from [previous] to be physically plausible
  /// in the elapsed time — a GPS teleport glitch that must be dropped so a
  /// single bad sample can't fake an entry or exit.
  static bool isTeleport(GeoFix fix, GeoFix? previous) {
    if (previous == null) return false;
    final seconds = fix.timestampUtc
        .difference(previous.timestampUtc)
        .inSeconds
        .abs();
    if (seconds <= 0) return false;
    final moved = distanceMeters(
      lat1: previous.latitude,
      lng1: previous.longitude,
      lat2: fix.latitude,
      lng2: fix.longitude,
    );
    return moved / seconds > GeofenceConfig.maxPlausibleSpeedMps;
  }
}
