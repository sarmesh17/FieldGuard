import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/dto/task_detail_response.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';

abstract class TasksRepository {
  Future<Result<TasksListResponse>> getTasks({
    int page,
    int limit,
    String? search,
    String? status,
    String? priority,
    int? userId,
    int? managerId,
    bool? hasManager,
    String? sortBy,
    String? sortOrder,
  });

  Future<Result<TaskDetailResponse>> getTaskDetail(int id);
}
