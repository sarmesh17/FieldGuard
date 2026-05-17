import 'package:fieldguard/core/constant/api_constant.dart';

/// Single source of truth for live-tracking socket configuration.
///
/// If the backend handshake / event names differ, change them HERE only —
/// nothing else in the app hard-codes these strings.
class SocketConstants {
  SocketConstants._();

  /// Socket.IO server origin. Same host as the REST API.
  static const String url = ApiConstant.baseUrl;

  /// Socket.IO path (default `/socket.io`). Change if backend uses a custom one.
  static const String path = '/socket.io';

  // ─── Outgoing (client → server) ───────────────────────────────────────────
  /// Manager/employee starts a field session.
  static const String trackingStart = 'tracking:start';

  /// Manager/employee stops the field session.
  static const String trackingStop = 'tracking:stop';

  /// Periodic location ping from this device.
  static const String locationUpdate = 'location:update';

  // ─── Incoming (server → client) ───────────────────────────────────────────
  /// A team employee moved — `{ employeeId, latitude, longitude, ... }`.
  static const String employeeLocation = 'employee:location';

  /// A team employee came online / went offline.
  static const String employeeOnline = 'employee:online';
  static const String employeeOffline = 'employee:offline';

  /// Socket.IO lifecycle events.
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String connectError = 'connect_error';
  static const String error = 'error';
}
