/// Response for `GET /api/v1/employees/{id}/history`.
///
/// Two shapes share this endpoint:
///   • No `sessionId` → a list of **session summaries**:
///     `{ "sessions": [ { id, startedAt, endedAt, isActive, totalDistance,
///        points /* a COUNT */ } ] }`
///   • With `?sessionId=` → the GPS **breadcrumbs** of one session:
///     `{ "points": [ { id, latitude, longitude, recordedAt, … } ] }`
///
/// The parser is tolerant of both shapes plus the key-name variants the
/// backend has used (`history` / `data`, snake/camel case, bare lists).
class TrackingHistoryResponse {
  final List<TrackingSession> sessions;
  final List<TrackingPoint> points;

  const TrackingHistoryResponse({
    this.sessions = const [],
    this.points = const [],
  });

  factory TrackingHistoryResponse.fromJson(Map<String, dynamic> json) {
    // ── Sessions (summary view) ──────────────────────────────────────────
    final rawSessions = json['sessions'] ?? json['history'] ?? json['data'];
    final sessions = rawSessions is List
        ? rawSessions
            .whereType<Map<String, dynamic>>()
            .map(TrackingSession.fromJson)
            .toList(growable: false)
        : const <TrackingSession>[];

    // ── Points (detail view, sessionId filter) ───────────────────────────
    // The `?sessionId=` call returns `{ route: [ { latitude, longitude,
    // accuracy, speed, bearing, recordedAt } ] }`. Also tolerate the older
    // key variants, and points nested inside a session object. A session's
    // `points` is only treated as breadcrumbs when it's a List — in the
    // summary shape it's an integer count.
    var rawPoints = json['route'] ??
        json['points'] ??
        json['locations'] ??
        json['breadcrumbs'];
    if (rawPoints is! List && rawSessions is List) {
      for (final s in rawSessions) {
        if (s is Map && s['points'] is List) {
          rawPoints = s['points'];
          break;
        }
      }
    }
    final points = rawPoints is List
        ? rawPoints
            .whereType<Map<String, dynamic>>()
            .map(TrackingPoint.fromJson)
            .toList(growable: false)
        : const <TrackingPoint>[];

    return TrackingHistoryResponse(sessions: sessions, points: points);
  }
}

/// A single tracking session summary (no GPS points, just aggregates).
class TrackingSession {
  final int id;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool isActive;

  /// Total distance travelled, in metres (as sent by the backend).
  final double totalDistance;

  /// Number of GPS breadcrumbs recorded in this session.
  final int pointCount;

  const TrackingSession({
    required this.id,
    this.startedAt,
    this.endedAt,
    this.isActive = false,
    this.totalDistance = 0,
    this.pointCount = 0,
  });

  Duration? get duration => (startedAt != null && endedAt != null)
      ? endedAt!.difference(startedAt!).abs()
      : null;

  factory TrackingSession.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    DateTime? toDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;

    return TrackingSession(
      id: toInt(json['id']),
      startedAt: toDate(json['startedAt'] ?? json['started_at']),
      endedAt: toDate(json['endedAt'] ?? json['ended_at']),
      isActive: json['isActive'] == true || json['is_active'] == true,
      totalDistance: toDouble(json['totalDistance'] ?? json['total_distance']),
      // `points` here is a count; tolerate explicit count keys too.
      pointCount:
          toInt(json['points'] ?? json['pointCount'] ?? json['point_count']),
    );
  }
}

class TrackingPoint {
  final int id;
  final int employeeId;
  final int? sessionId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? bearing;
  final String recordedAt;
  final String createdAt;

  const TrackingPoint({
    required this.id,
    required this.employeeId,
    this.sessionId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.bearing,
    required this.recordedAt,
    required this.createdAt,
  });

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return TrackingPoint(
      id: toInt(json['id']) ?? 0,
      employeeId: toInt(json['employeeId'] ?? json['employee_id']) ?? 0,
      sessionId: toInt(json['sessionId'] ?? json['session_id']),
      latitude: toDouble(json['latitude'] ?? json['lat']) ?? 0,
      longitude: toDouble(json['longitude'] ?? json['lng'] ?? json['lon']) ?? 0,
      accuracy: toDouble(json['accuracy']),
      speed: toDouble(json['speed']),
      bearing: toDouble(json['bearing'] ?? json['heading']),
      recordedAt: (json['recordedAt'] ?? json['recorded_at'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? json['created_at'] ?? '').toString(),
    );
  }
}
