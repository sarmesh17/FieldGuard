import 'package:fieldguard/features/tasks/data/dto/create_task_response.dart';

/// Response for `PATCH /api/v1/tasks/{id}`.
///
/// The server returns the updated task (same envelope as create / detail:
/// `{ "task": { ... } }`). Per the API the task also carries its full
/// `history` audit timeline; [TaskData] ignores keys it doesn't model, so
/// that extra data is simply not surfaced yet (see TaskData).
class UpdateTaskResponse {
  final TaskData task;

  const UpdateTaskResponse({required this.task});

  factory UpdateTaskResponse.fromJson(Map<String, dynamic> json) {
    return UpdateTaskResponse(
      task: TaskData.fromJson(json['task'] as Map<String, dynamic>),
    );
  }
}
