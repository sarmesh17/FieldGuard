import 'package:fieldguard/features/tasks/data/dto/create_task_response.dart';

/// Full task data from `GET /api/v1/tasks/:id`.
///
/// Reuses [TaskData] which already models every field returned by the
/// detail endpoint (description, items, coordinates, remarks, etc.).
class TaskDetailResponse {
  final TaskData task;

  const TaskDetailResponse({required this.task});

  factory TaskDetailResponse.fromJson(Map<String, dynamic> json) {
    return TaskDetailResponse(
      task: TaskData.fromJson(json['task'] as Map<String, dynamic>),
    );
  }
}
