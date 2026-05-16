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

  const TaskSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
    required this.assignee,
    this.manager,
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
    );
  }
}

class TaskPerson {
  final int id;
  final String fullName;
  final String? employeeCode;

  const TaskPerson({
    required this.id,
    required this.fullName,
    this.employeeCode,
  });

  factory TaskPerson.fromJson(Map<String, dynamic> json) {
    return TaskPerson(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      employeeCode: json['employee_code'] as String?,
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
