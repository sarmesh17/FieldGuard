import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:fieldguard/core/services/notification_service.dart';
import 'package:fieldguard/features/auto_geofence/service/auto_geofence_service.dart';

/// Foreground background-service that keeps automatic geofence detection alive
/// in a SEPARATE Dart isolate — surviving the UI being backgrounded OR the app
/// process being swipe-killed (a plain in-UI stream dies with the process).
///
/// The heavy lifting is reused: the isolate runs the very same
/// [AutoGeofenceService] the app already trusts (it self-fetches IN_PROGRESS
/// tasks, owns the location stream, persists the open visit, and uploads with
/// retry). The ONLY thing layered on here is: (a) running it off the UI
/// isolate, and (b) firing the arrival/exit notification from THIS isolate so
/// the alert still shows when the UI is dead.
///
/// Isolate model: [_onStart] runs in its own isolate with its own memory — it
/// does NOT share the UI's singletons. UI ↔ service talk over
/// `service.invoke()` / `service.on()`. Detection runs ONLY here; the UI's
/// [AutoGeofenceService] instance stays idle and just consumes forwarded
/// `geofence-event`s — so there is never double detection / double upload.
class BackgroundLocationService {
  BackgroundLocationService._();

  static const _notifId = 9911;

  /// Call once in `main()` BEFORE `runApp`. Registers the isolate entry point.
  /// `autoStart: false` — the service only runs while a task is IN_PROGRESS
  /// (started/stopped from the task→geofence sync).
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: NotificationService.foregroundServiceChannelId,
        initialNotificationTitle: 'FieldGuard',
        initialNotificationContent:
            'Tracking your location for automatic visit detection.',
        foregroundServiceNotificationId: _notifId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<bool> isRunning() => FlutterBackgroundService().isRunning();

  /// Starts the foreground service (no-op if already running).
  static Future<void> start() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) return;
    await service.startService();
  }

  /// Asks the isolate to stop itself.
  static void stop() => FlutterBackgroundService().invoke('stopService');

  /// Pings the isolate to re-fetch tasks immediately (instant arm/disarm after
  /// an in-app task change, instead of waiting for the service's poll).
  static void refresh() => FlutterBackgroundService().invoke('refresh');

  /// Stream of geofence transitions forwarded from the isolate. Each event is
  /// `{type: 'enter'|'exit'|'uploaded', taskId: int}`. Delivered only while the
  /// UI is alive — a missed event doesn't lose the visit (the isolate persists
  /// + uploads it regardless).
  static Stream<Map<String, dynamic>?> geofenceEvents() =>
      FlutterBackgroundService().on('geofence-event');
}

/// iOS background-fetch hook — required by the plugin even if unused for now.
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

/// Service isolate entry point. Runs independently of the UI; everything here
/// is self-contained (no UI singletons / no Riverpod).
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  // A binding + the plugin registrant are required before any plugin
  // (geolocator, secure storage, notifications, dio) works in this isolate.
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  debugPrint('[bg-service] isolate started');

  // Notification channel + permission setup, so the isolate can fire the
  // arrival/exit alert itself (this is what makes it survive an app-kill).
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('[bg-service] notification init failed: $e');
  }

  final geofence = AutoGeofenceService.instance;

  // Fire the alert FROM THIS ISOLATE on enter/exit. When the app is alive the
  // in-app bridge ALSO fires (with the real shop name) using the same
  // notification id, so the named alert just overwrites this generic one — no
  // duplicate. When the app is dead, only this one shows.
  geofence.onEnter = (taskId) {
    service.invoke('geofence-event', {'type': 'enter', 'taskId': taskId});
    NotificationService.instance.show(
      id: NotificationService.geofenceAlertId,
      title: 'You reached your destination',
      body: 'You have arrived at your task location.',
    );
  };
  geofence.onRealExit = (taskId) {
    service.invoke('geofence-event', {'type': 'exit', 'taskId': taskId});
    NotificationService.instance.show(
      id: NotificationService.geofenceAlertId,
      title: 'Task completed',
      body: 'You left your task location — the task was marked completed.',
    );
  };
  geofence.onVisitUploaded = (taskId, _) {
    service.invoke('geofence-event', {'type': 'uploaded', 'taskId': taskId});
  };

  // Re-fetch tasks on demand (UI ping after an in-app task change).
  service.on('refresh').listen((_) => geofence.refreshNow());

  // Stop cleanly when the UI says there's no IN_PROGRESS task / on logout.
  service.on('stopService').listen((_) async {
    await geofence.stop();
    await service.stopSelf();
  });

  // Start detection. AutoGeofenceService recovers any open visit, flushes the
  // upload queue, fetches IN_PROGRESS tasks, and arms the location stream.
  // Wrapped so a failure (e.g. auth/secure-storage hiccup in this isolate)
  // surfaces in logcat instead of silently killing the isolate.
  try {
    debugPrint('[bg-service] starting geofence detection…');
    await geofence.start();
    debugPrint('[bg-service] geofence detection started');
  } catch (e, st) {
    debugPrint('[bg-service] geofence.start() FAILED: $e\n$st');
  }
}
