import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps `geolocator` for field tracking with **background** support:
/// an Android foreground service notification + iOS background updates,
/// so the manager keeps streaming location while the app is backgrounded
/// (not killed). Foreground-only still works if "Always" is denied.
class LocationTracker {
  LocationTracker._();
  static final LocationTracker instance = LocationTracker._();

  StreamSubscription<Position>? _sub;
  bool get isTracking => _sub != null;

  /// Ensures location services + permission. Returns false if the user
  /// blocked it entirely. "Always" is requested for background but a
  /// "While in use" grant is still accepted (foreground tracking only).
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // Upgrade to background ("Always") — best effort.
    if (permission == LocationPermission.whileInUse) {
      await Permission.locationAlways.request();
    }
    return true;
  }

  /// Start the position stream. [onPosition] fires for every fix.
  /// Returns false if permission/services are unavailable.
  Future<bool> start({
    required void Function(Position) onPosition,
    int distanceFilterMeters = 10,
  }) async {
    if (_sub != null) return true;
    if (!await ensurePermission()) return false;

    _sub = Geolocator.getPositionStream(
      locationSettings: _settings(distanceFilterMeters),
    ).listen(onPosition, onError: (_) {});
    return true;
  }

  LocationSettings _settings(int distanceFilter) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'FieldGuard live tracking',
          notificationText: 'Sharing your location with your team',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
