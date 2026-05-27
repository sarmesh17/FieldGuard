/// Response for `GET /api/v1/employees/{id}/history` — tracking session
/// history for a field user. Returns a list of GPS breadcrumbs grouped by
/// optional `sessionId`.
class TrackingHistoryResponse {
  final List<TrackingPoint> points;

  const TrackingHistoryResponse({required this.points});

  /// Tolerant parser — accepts `{history: []}`, `{data: []}`, `{points: []}`,
  /// or a bare `[]`.
  factory TrackingHistoryResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['history'] ?? json['data'] ?? json['points'] ?? [];
    final list = (raw as List)
        .map((e) => TrackingPoint.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return TrackingHistoryResponse(points: list);
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
