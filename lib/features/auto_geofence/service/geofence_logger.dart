import 'package:flutter/foundation.dart';

/// Lightweight debug-only logger for geofence diagnostics.
///
/// Emits to the console via [debugPrint] in debug builds only — in release the
/// [kDebugMode] guard makes every call a no-op. It deliberately keeps NO
/// in-memory buffer: the on-device log viewer was removed, so retaining the
/// last N entries (and allocating an entry + notifying listeners on every GPS
/// fix) would just be dead weight on the detection hot path.
class GeofenceLogger {
  GeofenceLogger._();
  static final GeofenceLogger instance = GeofenceLogger._();

  void debug(String tag, String message) => _log('🔍', tag, message);
  void info(String tag, String message) => _log('ℹ️', tag, message);
  void warn(String tag, String message) => _log('⚠️', tag, message);
  void error(String tag, String message) => _log('❌', tag, message);

  void _log(String icon, String tag, String message) {
    if (kDebugMode) debugPrint('[$icon $tag] $message');
  }
}
