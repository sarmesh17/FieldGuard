class CreateTaskResponse {
  final TaskData task;

  const CreateTaskResponse({required this.task});

  factory CreateTaskResponse.fromJson(Map<String, dynamic> json) {
    return CreateTaskResponse(
      task: TaskData.fromJson(json['task'] as Map<String, dynamic>),
    );
  }
}

class TaskData {
  final int id;
  final int? companyId;
  final int? assignedTo;
  final int? assignedBy;
  final int? managerId;
  final String title;
  final String description;
  final List<String> items;
  final String status;
  final String priority;
  // Legacy fields: tasks created before the shopId-only migration may still
  // carry raw coordinates without a linked shop. Newer tasks resolve them
  // server-side from [shop].
  final String? shopLatitude;
  final String? shopLongitude;
  final TaskShop? shop;
  final String dueDate;
  final String? completedAt;
  final String? remarks;
  final String createdAt;
  final String updatedAt;
  final Assignee assignee;
  final Creator creator;
  final Manager? manager;
  // Cancellation fields (null when not cancelled or when reason is OTHER)
  final String? cancelReason;
  final String? cancelImage; // full CDN URL returned by the server
  // Geofence visit timeline, enter-time ascending. Always present (never
  // null): an empty list means no visits were recorded yet.
  final List<TaskGeofenceVisit> geofenceVisits;

  const TaskData({
    required this.id,
    this.companyId,
    this.assignedTo,
    this.assignedBy,
    this.managerId,
    required this.title,
    required this.description,
    required this.items,
    required this.status,
    required this.priority,
    this.shopLatitude,
    this.shopLongitude,
    this.shop,
    required this.dueDate,
    this.completedAt,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    required this.assignee,
    required this.creator,
    this.manager,
    this.cancelReason,
    this.cancelImage,
    this.geofenceVisits = const [],
  });

  factory TaskData.fromJson(Map<String, dynamic> json) {
    return TaskData(
      id: json['id'] as int,
      companyId: json['company_id'] as int?,
      assignedTo: json['assigned_to'] as int?,
      assignedBy: json['assigned_by'] as int?,
      managerId: json['manager_id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      items: (json['items'] as List<dynamic>).map((e) => e.toString()).toList(),
      status: json['status'] as String,
      priority: json['priority'] as String,
      shopLatitude: json['shop_latitude'] as String?,
      shopLongitude: json['shop_longitude'] as String?,
      shop: json['shop'] != null
          ? TaskShop.fromJson(json['shop'] as Map<String, dynamic>)
          : null,
      dueDate: json['due_date'] as String,
      completedAt: json['completed_at'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      assignee: Assignee.fromJson(json['assignee'] as Map<String, dynamic>),
      creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
      manager: json['manager'] != null
          ? Manager.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
      cancelReason: json['cancel_reason'] as String?,
      cancelImage: json['cancel_image'] as String?,
      geofenceVisits: (json['geofence_visits'] as List<dynamic>? ?? const [])
          .map((e) => TaskGeofenceVisit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A single geofence visit from `GET /api/v1/tasks/:id`'s `geofence_visits`
/// array (enter-time ascending). Coordinates arrive as DB-decimal strings and
/// timestamps as ISO 8601; we parse them eagerly here so the UI gets typed
/// values. Distinct from `auto_geofence`'s [GeofenceVisit], which models the
/// camelCase *upload* request body — this is the server's read shape.
class TaskGeofenceVisit {
  final String id; // server UUID
  final String visitId; // client idempotency key
  final int? shopId;
  final DateTime enteredAt;
  final DateTime exitedAt;
  final int stayDurationSeconds;
  final double enterLatitude;
  final double enterLongitude;
  final double exitLatitude;
  final double exitLongitude;

  /// True when the exit was estimated (app killed / location permission lost)
  /// rather than observed as a clean crossing.
  final bool exitEstimated;

  const TaskGeofenceVisit({
    required this.id,
    required this.visitId,
    this.shopId,
    required this.enteredAt,
    required this.exitedAt,
    required this.stayDurationSeconds,
    required this.enterLatitude,
    required this.enterLongitude,
    required this.exitLatitude,
    required this.exitLongitude,
    required this.exitEstimated,
  });

  factory TaskGeofenceVisit.fromJson(Map<String, dynamic> json) {
    double parseCoord(dynamic v) => double.tryParse('${v ?? ''}') ?? 0.0;
    return TaskGeofenceVisit(
      id: json['id']?.toString() ?? '',
      visitId: json['visit_id']?.toString() ?? '',
      shopId: (json['shop_id'] as num?)?.toInt(),
      enteredAt: DateTime.parse(json['entered_at'] as String),
      exitedAt: DateTime.parse(json['exited_at'] as String),
      stayDurationSeconds: (json['stay_duration_seconds'] as num?)?.toInt() ?? 0,
      enterLatitude: parseCoord(json['enter_latitude']),
      enterLongitude: parseCoord(json['enter_longitude']),
      exitLatitude: parseCoord(json['exit_latitude']),
      exitLongitude: parseCoord(json['exit_longitude']),
      exitEstimated: json['exit_estimated'] as bool? ?? false,
    );
  }
}

/// Minimal shop payload embedded in task responses — enough to render a
/// thumbnail + name. Full shop data is fetched separately when needed.
class TaskShop {
  final int id;
  final String name;
  final String? shopImage;
  final String? address;
  final String? latitude;
  final String? longitude;

  const TaskShop({
    required this.id,
    required this.name,
    this.shopImage,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory TaskShop.fromJson(Map<String, dynamic> json) {
    return TaskShop(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      shopImage: json['shop_image'] as String?,
      address: json['address'] as String?,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }
}

class Assignee {
  final int id;
  final String fullName;
  final String employeeCode;

  const Assignee({
    required this.id,
    required this.fullName,
    required this.employeeCode,
  });

  factory Assignee.fromJson(Map<String, dynamic> json) {
    return Assignee(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      employeeCode: json['employee_code'] as String,
    );
  }
}

class Creator {
  final int id;
  final String fullName;

  const Creator({
    required this.id,
    required this.fullName,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
    );
  }
}

class Manager {
  final int id;
  final String fullName;
  final String? managerCode;

  const Manager({
    required this.id,
    required this.fullName,
    this.managerCode,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      managerCode: json['manager_code'] as String?,
    );
  }
}
