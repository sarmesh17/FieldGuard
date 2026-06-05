import 'package:fieldguard/features/tasks/data/dto/create_task_response.dart';

/// Lightweight response for the task list/cards screen.
///
/// The list endpoint (`GET /api/v1/tasks`) returns summary data only —
/// no description, items, coordinates or remarks. Full data comes from
/// the detail endpoint (`GET /api/v1/tasks/:id`).
class TasksListResponse {
  final List<TaskSummary> tasks;
  final Pagination pagination;

  const TasksListResponse({required this.tasks, required this.pagination});

  factory TasksListResponse.fromJson(Map<String, dynamic> json) {
    return TasksListResponse(
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((e) => TaskSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class TaskSummary {
  final int id;
  final String title;
  final String status;
  final String priority;
  final String dueDate;
  final String createdAt;
  final TaskPerson assignee;
  final TaskPerson? manager;
  final TaskPerson? creator;
  final TaskShop? shop;

  // Creation-time snapshot of the shop's coordinates, copied onto the task
  // when it was created (survives shop edits, present even when [shop] is
  // null for legacy tasks). The list/my-tasks/detail endpoints all return
  // these as top-level strings — preferred for routing/geofencing over the
  // shop relation (which omits coords in summary payloads).
  final String? shopLatitude;
  final String? shopLongitude;

  const TaskSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
    required this.assignee,
    this.manager,
    this.creator,
    this.shop,
    this.shopLatitude,
    this.shopLongitude,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      assignee: TaskPerson.fromJson(
        json['assignee'] as Map<String, dynamic>? ?? const {},
      ),
      manager: json['manager'] != null
          ? TaskPerson.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
      // Who created the task — ADMIN or a MANAGER. Drives the "Created by"
      // chip on the card so the assigner is never hidden.
      creator: json['creator'] != null
          ? TaskPerson.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      shop: json['shop'] != null
          ? TaskShop.fromJson(json['shop'] as Map<String, dynamic>)
          : null,
      shopLatitude: json['shop_latitude']?.toString(),
      shopLongitude: json['shop_longitude']?.toString(),
    );
  }
}

/// Resolves a task's shop coordinates for routing/geofencing, preferring the
/// top-level snapshot ([TaskSummary.shopLatitude]/[shopLongitude]) and falling
/// back to the embedded shop relation. Returns null when neither is parseable.
({double lat, double lng})? taskShopLatLng(TaskSummary t) {
  final lat = double.tryParse(t.shopLatitude ?? t.shop?.latitude ?? '');
  final lng = double.tryParse(t.shopLongitude ?? t.shop?.longitude ?? '');
  if (lat == null || lng == null) return null;
  return (lat: lat, lng: lng);
}

class TaskPerson {
  final int id;
  final String fullName;
  final String? employeeCode;

  /// `EMPLOYEE`, `MANAGER` or `ADMIN`. Present on `assignee` (to split the
  /// Manager/Employee tabs) and on `creator` (to label who assigned it).
  final String? role;

  const TaskPerson({
    required this.id,
    required this.fullName,
    this.employeeCode,
    this.role,
  });

  factory TaskPerson.fromJson(Map<String, dynamic> json) {
    return TaskPerson(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      employeeCode: json['employee_code'] as String?,
      role: json['role'] as String?,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
