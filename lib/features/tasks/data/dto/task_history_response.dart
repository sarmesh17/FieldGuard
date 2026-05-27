import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart'
    show Pagination;

/// Response for `GET /api/v1/tasks/history` — the role-scoped task audit
/// feed ("who changed what, when, from where and why"). Newest first.
///
/// Shapes mirror the backend `taskHistorySelect` projection. `old_values`
/// / `new_values` are arbitrary JSON blobs (the changed fields), and the
/// "why" lives in `new_values.changeReason`. A row's `task` may be just
/// `{ id }` when the underlying task is no longer visible/found.
class TaskHistoryResponse {
  final List<TaskHistoryEntry> history;
  final Pagination pagination;

  const TaskHistoryResponse({
    required this.history,
    required this.pagination,
  });

  factory TaskHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TaskHistoryResponse(
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => TaskHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class TaskHistoryEntry {
  final int id;
  final String action; // e.g. TASK_UPDATED
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String createdAt;
  final TaskHistoryPerformer? performer;
  final TaskHistoryTaskRef task;

  const TaskHistoryEntry({
    required this.id,
    required this.action,
    required this.oldValues,
    required this.newValues,
    required this.ipAddress,
    required this.createdAt,
    required this.performer,
    required this.task,
  });

  /// The "why" behind a sensitive change (cancel / reopen) — the API tucks
  /// it inside `new_values.changeReason`.
  String? get changeReason {
    final r = newValues?['changeReason'];
    return r is String && r.trim().isNotEmpty ? r : null;
  }

  factory TaskHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TaskHistoryEntry(
      id: json['id'] as int? ?? 0,
      action: json['action'] as String? ?? '',
      oldValues: _asMap(json['old_values']),
      newValues: _asMap(json['new_values']),
      ipAddress: json['ip_address'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      performer: json['performer'] is Map
          ? TaskHistoryPerformer.fromJson(
              json['performer'] as Map<String, dynamic>)
          : null,
      task: TaskHistoryTaskRef.fromJson(
        json['task'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// Audit blobs come back as JSON objects; tolerate null / non-map shapes.
Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class TaskHistoryPerformer {
  final int id;
  final String fullName;
  final String? role;

  const TaskHistoryPerformer({
    required this.id,
    required this.fullName,
    this.role,
  });

  factory TaskHistoryPerformer.fromJson(Map<String, dynamic> json) {
    return TaskHistoryPerformer(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? 'Unknown',
      role: json['role'] as String?,
    );
  }
}

/// Lightweight task context attached to each row. `title` / `status` /
/// people are null when the task couldn't be resolved (row is `{ id }`).
class TaskHistoryTaskRef {
  final int id;
  final String? title;
  final String? status;
  final TaskHistoryPerson? assignee;
  final TaskHistoryPerson? manager;

  const TaskHistoryTaskRef({
    required this.id,
    this.title,
    this.status,
    this.assignee,
    this.manager,
  });

  factory TaskHistoryTaskRef.fromJson(Map<String, dynamic> json) {
    return TaskHistoryTaskRef(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String?,
      status: json['status'] as String?,
      assignee: json['assignee'] is Map
          ? TaskHistoryPerson.fromJson(
              json['assignee'] as Map<String, dynamic>)
          : null,
      manager: json['manager'] is Map
          ? TaskHistoryPerson.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TaskHistoryPerson {
  final int id;
  final String fullName;

  const TaskHistoryPerson({required this.id, required this.fullName});

  factory TaskHistoryPerson.fromJson(Map<String, dynamic> json) {
    return TaskHistoryPerson(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
    );
  }
}
