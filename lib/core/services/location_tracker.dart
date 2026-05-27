import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// One shared location stream for the whole app.
///
/// Both field tracking (slide-to-track) and the auto-geofence visit
/// tracker consume this single broadcast stream, so there is only ever
/// ONE underlying `getPositionStream` and ONE Android foreground-service
/// notification — never two competing ones.
///
/// Consumers ref-count the stream with [acquire] / [release]: the
/// underlying stream starts on the first acquisition and stops only once
/// the last holder releases. Background support (Android foreground
/// service + iOS background updates) keeps fixes flowing while the app is
/// backgrounded (not killed).
class LocationTracker {
  LocationTracker._();
  static final LocationTracker instance = LocationTracker._();

  /// Distance filter for the shared stream. Tight enough for geofence edge
  /// precision; field tracking is happy with finer updates too.
  static const int _distanceFilterMeters = 5;

  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();
  final Set<Object> _holders = <Object>{};
  StreamSubscription<Position>? _sub;
  Position? _lastPosition;

  // Token + subscription backing the legacy single-callback [start] API.
  static const Object _legacyToken = #locationTrackerLegacyCallback;
  StreamSubscription<Position>? _legacySub;

  /// Broadcast position fixes. Listen only while holding the stream via
  /// [acquire]; multiple simultaneous listeners are supported.
  Stream<Position> get stream => _controller.stream;

  /// The most recent fix, or null before the first one arrives. Lets a
  /// consumer evaluate immediately on [acquire] instead of waiting for the
  /// next movement.
  Position? get lastPosition => _lastPosition;

  bool get isActive => _sub != null;

  /// Ensures location services + permission. Returns false if blocked.
  /// "Always" is requested for background but a "While in use" grant is
  /// still accepted (foreground-only operation).
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
    if (permission == LocationPermission.whileInUse) {
      await Permission.locationAlways.request();
    }
    return true;
  }

  /// Acquire the shared stream under [token]. Starts the underlying stream
  /// on the first acquisition. Returns false if permission/services are
  /// unavailable. Re-acquiring with the same token is a no-op.
  Future<bool> acquire(Object token) async {
    if (_sub == null) {
      if (!await ensurePermission()) return false;
      _sub =
          Geolocator.getPositionStream(locationSettings: _settings()).listen(
            (p) {
              _lastPosition = p;
              if (!_controller.isClosed) _controller.add(p);
            },
            onError: (_) {},
          );
    }
    _holders.add(token);
    return true;
  }

  /// Release [token]. Stops the underlying stream once no holders remain.
  Future<void> release(Object token) async {
    _holders.remove(token);
    if (_holders.isEmpty) {
      await _sub?.cancel();
      _sub = null;
    }
  }

  /// Backward-compatible single-callback start (field slide-to-track):
  /// acquires the shared stream and routes its fixes to [onPosition].
  Future<bool> start({required void Function(Position) onPosition}) async {
    final ok = await acquire(_legacyToken);
    if (!ok) return false;
    _legacySub ??= _controller.stream.listen(onPosition);
    return true;
  }

  /// Stop the legacy single-callback consumer.
  Future<void> stop() async {
    await _legacySub?.cancel();
    _legacySub = null;
    await release(_legacyToken);
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'FieldGuard',
          notificationText:
              'Location is active for field tracking and visit detection',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _distanceFilterMeters,
    );
  }
}
