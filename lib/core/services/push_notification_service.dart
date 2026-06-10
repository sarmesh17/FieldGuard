import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/router/app_router.dart';
import 'package:fieldguard/core/services/notification_service.dart';
import 'package:fieldguard/features/notifications/presentation/notification_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Background / terminated message handler. Must be a top-level function and
/// annotated so it survives tree-shaking — it runs in its own isolate.
///
/// "notification" messages are shown by the OS automatically when the app is
/// backgrounded, so there's nothing to render here. We only initialise Firebase
/// in case we later need to process data-only messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Wraps Firebase Cloud Messaging: permission, token, and foreground delivery.
///
/// FCM does NOT display a notification while the app is in the foreground, so we
/// render those ourselves via [NotificationService] (the OS handles background /
/// terminated delivery). The FCM token identifies this device — send it to the
/// backend so the server can target this install.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialised = false;

  String? _token;

  /// The current FCM registration token (null until [init] resolves). Send this
  /// to the backend to target push at this device.
  String? get token => _token;

  /// Fires whenever a push arrives while the app is in the FOREGROUND. The
  /// notification center listens to this to re-sync its list + unread badge
  /// live (without the user pulling to refresh).
  final StreamController<void> _received = StreamController<void>.broadcast();
  Stream<void> get onNotificationReceived => _received.stream;

  /// One-time setup. Call after `Firebase.initializeApp()` in `main`.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // Asks for the notification permission (Android 13+ system prompt / iOS
    // APNs prompt). No-op if already decided.
    await _fcm.requestPermission();

    // iOS: also show banners while the app is in the foreground (on Android we
    // render foreground messages ourselves below).
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages — the OS won't show them, so render via local notifs.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Tap on a notification that opened/resumed the app (backgrounded case).
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
    final initial = await _fcm.getInitialMessage(); // launched from terminated
    if (initial != null) _onOpened(initial);

    try {
      _token = await _fcm.getToken();
      if (kDebugMode) debugPrint('[fcm] token: $_token');
    } catch (e) {
      if (kDebugMode) debugPrint('[fcm] getToken failed: $e');
    }
    // Token can rotate; keep ours fresh (and re-register with the backend).
    _fcm.onTokenRefresh.listen((t) {
      _token = t;
      if (kDebugMode) debugPrint('[fcm] token refreshed: $t');
      registerToken(); // re-register the rotated token (best-effort)
    });
  }

  /// POSTs this device's FCM token to the backend so the server can target push
  /// at this install. Requires auth — call after login (and on token refresh).
  /// Best-effort: any failure is swallowed so it never blocks the app.
  Future<void> registerToken() async {
    try {
      final token = _token ?? await _fcm.getToken();
      if (token == null || token.isEmpty) return;
      final info = await PackageInfo.fromPlatform();
      await DioClient.createDio().post(
        ApiConstant.pushTokenEndpoint,
        data: {
          'deviceId': await _deviceId(),
          'pushToken': token,
          'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
          'appVersion': info.version,
        },
      );
      if (kDebugMode) debugPrint('[fcm] token registered with backend');
    } catch (e) {
      if (kDebugMode) debugPrint('[fcm] registerToken failed: $e');
    }
  }

  /// Tells the backend to drop this device's token. Call on logout BEFORE the
  /// auth tokens are cleared (the DELETE needs the still-valid JWT). Best-effort.
  Future<void> unregisterToken() async {
    try {
      await DioClient.createDio().delete(
        ApiConstant.pushTokenEndpoint,
        data: {'deviceId': await _deviceId()},
      );
      if (kDebugMode) debugPrint('[fcm] token unregistered');
    } catch (e) {
      if (kDebugMode) debugPrint('[fcm] unregisterToken failed: $e');
    }
  }

  void _showForeground(RemoteMessage message) {
    // Tell the notification center to re-sync (live badge + list update),
    // including for data-only messages that have nothing to display.
    _received.add(null);
    final n = message.notification;
    if (n == null) return; // data-only message — nothing to display
    NotificationService.instance.showPush(
      // Stable-ish id per message so rapid messages don't overwrite each other.
      id: message.messageId?.hashCode ?? message.hashCode,
      title: n.title ?? 'FieldGuard HQ',
      body: n.body ?? '',
    );
  }

  void _onOpened(RemoteMessage message) {
    final data = message.data;
    if (kDebugMode) debugPrint('[fcm] opened from notification: $data');
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    routeNotification(
      nav,
      kind: data['kind']?.toString(),
      shopId: data['shopId']?.toString(),
      taskId: data['taskId']?.toString(),
    );
  }

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
  static const String _deviceIdKey = 'fg_device_id';

  /// A stable per-install id, generated once and persisted. Android device ids
  /// are unreliable/privacy-restricted, so we mint our own UUID instead.
  Future<String> _deviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuidV4();
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  static String _uuidV4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 1
    String hex(int n) => n.toRadixString(16).padLeft(2, '0');
    final s = b.map(hex).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-'
        '${s.substring(16, 20)}-${s.substring(20)}';
  }
}
