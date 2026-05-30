import 'package:flutter/foundation.dart';

/// Severity level for geofence log entries.
enum GeoLogLevel { debug, info, warn, error }

/// A single timestamped log entry.
class GeoLogEntry {
  final DateTime timestamp;
  final GeoLogLevel level;
  final String tag;
  final String message;

  const GeoLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get timeString {
    final t = timestamp.toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.'
        '${t.millisecond.toString().padLeft(3, '0')}';
  }

  String get levelIcon => switch (level) {
        GeoLogLevel.debug => '🔍',
        GeoLogLevel.info => 'ℹ️',
        GeoLogLevel.warn => '⚠️',
        GeoLogLevel.error => '❌',
      };
}

/// In-memory ring-buffer logger for geofence diagnostics.
///
/// Stores the last [maxEntries] log entries and notifies listeners on each
/// new entry so the log viewer screen can rebuild reactively.
class GeofenceLogger {
  GeofenceLogger._();
  static final GeofenceLogger instance = GeofenceLogger._();

  static const int maxEntries = 500;

  final List<GeoLogEntry> _entries = [];
  List<GeoLogEntry> get entries => List.unmodifiable(_entries);

  /// Incremented on every log call — listen to this in the UI.
  final ValueNotifier<int> changeNotifier = ValueNotifier(0);

  void _log(GeoLogLevel level, String tag, String message) {
    final entry = GeoLogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    changeNotifier.value++;
    if (kDebugMode) {
      debugPrint('[${entry.levelIcon} $tag] $message');
    }
  }

  void debug(String tag, String message) =>
      _log(GeoLogLevel.debug, tag, message);
  void info(String tag, String message) =>
      _log(GeoLogLevel.info, tag, message);
  void warn(String tag, String message) =>
      _log(GeoLogLevel.warn, tag, message);
  void error(String tag, String message) =>
      _log(GeoLogLevel.error, tag, message);

  void clear() {
    _entries.clear();
    changeNotifier.value++;
  }
}
