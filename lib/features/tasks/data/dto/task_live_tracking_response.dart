/// Response for `GET /api/v1/tasks/{id}/live-tracking` — the one-shot
/// snapshot used to drop the initial pin before the socket stream takes
/// over. `location` is null until the assignee's app has pushed a fresh
/// fix (snapshot < 30s old AND tracking on), so `isLive` may be false.
class TaskLiveTrackingResponse {
  final int taskId;
  final int? employeeId;
  final bool isLive;
  final int viewerCount;
  final TaskLiveLocation? location;

  const TaskLiveTrackingResponse({
    required this.taskId,
    required this.employeeId,
    required this.isLive,
    required this.viewerCount,
    required this.location,
  });

  factory TaskLiveTrackingResponse.fromJson(Map<String, dynamic> json) {
    final loc = json['location'];
    return TaskLiveTrackingResponse(
      taskId: json['task_id'] as int? ?? json['taskId'] as int? ?? 0,
      employeeId: json['employee_id'] as int? ?? json['employeeId'] as int?,
      isLive: json['is_live'] as bool? ?? json['isLive'] as bool? ?? false,
      viewerCount:
          json['viewer_count'] as int? ?? json['viewerCount'] as int? ?? 0,
      location: loc is Map<String, dynamic>
          ? TaskLiveLocation.fromJson(loc)
          : null,
    );
  }
}

class TaskLiveLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? bearing;
  final String? recordedAt;

  const TaskLiveLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.bearing,
    this.recordedAt,
  });

  static double? _toDouble(dynamic v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  factory TaskLiveLocation.fromJson(Map<String, dynamic> json) {
    return TaskLiveLocation(
      latitude: _toDouble(json['latitude']) ?? 0,
      longitude: _toDouble(json['longitude']) ?? 0,
      accuracy: _toDouble(json['accuracy']),
      speed: _toDouble(json['speed']),
      bearing: _toDouble(json['bearing']) ?? _toDouble(json['heading']),
      recordedAt:
          (json['recorded_at'] ?? json['recordedAt'])?.toString(),
    );
  }
}
