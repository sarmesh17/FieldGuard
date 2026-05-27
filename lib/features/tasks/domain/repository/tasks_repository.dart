import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/dto/task_detail_response.dart';
import 'package:fieldguard/features/tasks/data/dto/task_history_response.dart';
import 'package:fieldguard/features/tasks/data/dto/task_live_tracking_response.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/tasks/data/dto/update_task_request.dart';
import 'package:fieldguard/features/tasks/data/dto/update_task_response.dart';

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
    String? assigneeRole,
    int? createdBy,
    String? view,
    String? sortBy,
    String? sortOrder,
  });

  Future<Result<TaskDetailResponse>> getTaskDetail(int id);

  Future<Result<UpdateTaskResponse>> updateTask(
    int id,
    UpdateTaskRequest request,
  );

  Future<Result<TaskHistoryResponse>> getTaskHistory({
    int? taskId,
    int? userId,
    int? managerId,
    int? performedBy,
    String? action,
    String? from,
    String? to,
    int page,
    int limit,
    String sortOrder,
  });

  Future<Result<TaskLiveTrackingResponse>> getTaskLiveTracking(int id);
}
