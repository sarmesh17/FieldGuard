/// A tolerant lat/lng parser.
///
/// The backend's `location` shape is still in flux (it arrives `null` in the
/// `/employees/live` sample), so we accept the common variants instead of
/// hard-failing: `latitude/longitude`, `lat/lng`, `lat/lon`, or a GeoJSON-ish
/// `coordinates: [lng, lat]`.
class LiveLatLng {
  final double latitude;
  final double longitude;

  const LiveLatLng(this.latitude, this.longitude);

  static LiveLatLng? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();

    double? toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final lat = toDouble(map['latitude']) ?? toDouble(map['lat']);
    final lng = toDouble(map['longitude']) ??
        toDouble(map['lng']) ??
        toDouble(map['lon']);
    if (lat != null && lng != null) return LiveLatLng(lat, lng);

    // GeoJSON style: { coordinates: [lng, lat] }
    final coords = map['coordinates'];
    if (coords is List && coords.length >= 2) {
      final cLng = toDouble(coords[0]);
      final cLat = toDouble(coords[1]);
      if (cLat != null && cLng != null) return LiveLatLng(cLat, cLng);
    }
    return null;
  }
}

/// `employee:location` socket payload (also reused for the REST snapshot).
class EmployeeLocationEvent {
  final String employeeId;
  final LiveLatLng position;
  final double? speed;
  final double? heading;
  final DateTime? timestamp;

  const EmployeeLocationEvent({
    required this.employeeId,
    required this.position,
    this.speed,
    this.heading,
    this.timestamp,
  });

  static EmployeeLocationEvent? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();

    final id = (map['employeeId'] ??
            map['employee_id'] ??
            map['id'] ??
            map['userId'])
        ?.toString();
    if (id == null || id.isEmpty) return null;

    // lat/lng may sit at the top level or inside a nested `location` object.
    final pos = LiveLatLng.tryParse(map) ??
        LiveLatLng.tryParse(map['location']) ??
        LiveLatLng.tryParse(map['coords']);
    if (pos == null) return null;

    double? toDouble(dynamic v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

    DateTime? ts;
    final rawTs = map['timestamp'] ?? map['updatedAt'] ?? map['time'];
    if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(
          rawTs > 9999999999 ? rawTs : rawTs * 1000);
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs);
    }

    return EmployeeLocationEvent(
      employeeId: id,
      position: pos,
      speed: toDouble(map['speed']),
      heading: toDouble(map['heading']) ?? toDouble(map['bearing']),
      timestamp: ts,
    );
  }
}

/// `task:location` socket payload — the watched task's assignee moved.
///
/// Tolerant like [EmployeeLocationEvent]: lat/lng may be top-level or under
/// `location`, ids may be camel/snake, the employee block is optional.
class TaskLocationEvent {
  final String taskId;
  final String employeeId;
  final String? employeeName;
  final LiveLatLng position;
  final double? accuracy;
  final double? speed;
  final double? bearing;
  final DateTime? recordedAt;

  const TaskLocationEvent({
    required this.taskId,
    required this.employeeId,
    required this.position,
    this.employeeName,
    this.accuracy,
    this.speed,
    this.bearing,
    this.recordedAt,
  });

  static double? _toDouble(dynamic v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  static DateTime? _toDate(dynamic v) {
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(
          v > 9999999999 ? v : v * 1000);
    }
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static TaskLocationEvent? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();

    final taskId = (map['taskId'] ?? map['task_id'])?.toString();
    if (taskId == null || taskId.isEmpty) return null;

    final empId = (map['employeeId'] ??
            map['employee_id'] ??
            map['userId'] ??
            (map['employee'] is Map ? (map['employee'] as Map)['id'] : null))
        ?.toString();
    if (empId == null || empId.isEmpty) return null;

    final pos = LiveLatLng.tryParse(map) ??
        LiveLatLng.tryParse(map['location']) ??
        LiveLatLng.tryParse(map['coords']);
    if (pos == null) return null;

    String? name;
    final emp = map['employee'];
    if (emp is Map) {
      name = (emp['full_name'] ?? emp['fullName'] ?? emp['name'])?.toString();
    }

    return TaskLocationEvent(
      taskId: taskId,
      employeeId: empId,
      employeeName: name,
      position: pos,
      accuracy: _toDouble(map['accuracy']),
      speed: _toDouble(map['speed']),
      bearing: _toDouble(map['bearing']) ?? _toDouble(map['heading']),
      recordedAt: _toDate(map['recordedAt'] ??
          map['recorded_at'] ??
          map['timestamp'] ??
          map['updatedAt']),
    );
  }
}

/// `task:status_changed` socket payload.
class TaskStatusChangedEvent {
  final String taskId;
  final String status;
  final String? previousStatus;
  final DateTime? at;

  const TaskStatusChangedEvent({
    required this.taskId,
    required this.status,
    this.previousStatus,
    this.at,
  });

  static TaskStatusChangedEvent? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();

    final taskId = (map['taskId'] ?? map['task_id'])?.toString();
    final status = (map['status'])?.toString();
    if (taskId == null || taskId.isEmpty || status == null || status.isEmpty) {
      return null;
    }

    DateTime? at;
    final rawAt = map['at'] ?? map['changedAt'] ?? map['updatedAt'];
    if (rawAt is int) {
      at = DateTime.fromMillisecondsSinceEpoch(
          rawAt > 9999999999 ? rawAt : rawAt * 1000);
    } else if (rawAt is String) {
      at = DateTime.tryParse(rawAt);
    }

    return TaskStatusChangedEvent(
      taskId: taskId,
      status: status,
      previousStatus:
          (map['previousStatus'] ?? map['previous_status'])?.toString(),
      at: at,
    );
  }
}

/// `employee:online` / `employee:offline` socket payload.
class EmployeeOnlineEvent {
  final String employeeId;
  final bool online;

  const EmployeeOnlineEvent({required this.employeeId, required this.online});

  static EmployeeOnlineEvent? tryParse(dynamic raw, {required bool online}) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final id = (map['employeeId'] ??
            map['employee_id'] ??
            map['id'] ??
            map['userId'])
        ?.toString();
    if (id == null || id.isEmpty) return null;
    final flag = map['online'];
    return EmployeeOnlineEvent(
      employeeId: id,
      online: flag is bool ? flag : online,
    );
  }
}
