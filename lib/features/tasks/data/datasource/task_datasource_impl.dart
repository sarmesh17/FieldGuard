import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/features/tasks/data/dto/create_task_request.dart';
import 'package:fieldguard/features/tasks/data/dto/create_task_response.dart';
import 'package:fieldguard/features/tasks/data/dto/task_detail_response.dart';
import 'package:fieldguard/features/tasks/data/dto/task_history_response.dart';
import 'package:fieldguard/features/tasks/data/dto/task_live_tracking_response.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/tasks/data/dto/update_task_request.dart';
import 'package:fieldguard/features/tasks/data/dto/update_task_response.dart';

class TaskDataSourceImpl {
  final Dio _dio;

  TaskDataSourceImpl(this._dio);

  Future<CreateTaskResponse> createTask(CreateTaskRequest request) async {
    final response = await _dio.post(
      ApiConstant.tasksEndpoint,
      data: request.toJson(),
      options: Options(contentType: 'application/json'),
    );
    return CreateTaskResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TasksListResponse> getTasks({
    int page = 1,
    int limit = 20,
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
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (userId != null) params['userId'] = userId;
    if (managerId != null) params['managerId'] = managerId;
    if (hasManager != null) params['hasManager'] = hasManager;
    if (assigneeRole != null) params['assigneeRole'] = assigneeRole;
    if (createdBy != null) params['createdBy'] = createdBy;
    if (view != null) params['view'] = view;
    if (sortBy != null) params['sortBy'] = sortBy;
    if (sortOrder != null) params['sortOrder'] = sortOrder;

    final response = await _dio.get(
      ApiConstant.tasksEndpoint,
      queryParameters: params,
    );
    return TasksListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TaskDetailResponse> getTaskDetail(int id) async {
    final response = await _dio.get('${ApiConstant.tasksEndpoint}/$id');
    return TaskDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PATCH /api/v1/tasks/{id}` — update status and/or details. The body is
  /// a partial update; the server validates `changeReason` requirements and
  /// role permissions (EMPLOYEE editing priority/dueDate → 403).
  Future<UpdateTaskResponse> updateTask(
    int id,
    UpdateTaskRequest request,
  ) async {
    final response = await _dio.patch(
      '${ApiConstant.tasksEndpoint}/$id',
      data: request.toJson(),
      options: Options(contentType: 'application/json'),
    );
    return UpdateTaskResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /api/v1/tasks/history` — role-scoped task audit feed. All filters
  /// are optional; visibility is enforced server-side by the caller's role.
  Future<TaskHistoryResponse> getTaskHistory({
    int? taskId,
    int? userId,
    int? managerId,
    int? performedBy,
    String? action,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
    String sortOrder = 'desc',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortOrder': sortOrder,
    };
    if (taskId != null) params['taskId'] = taskId;
    if (userId != null) params['userId'] = userId;
    if (managerId != null) params['managerId'] = managerId;
    if (performedBy != null) params['performedBy'] = performedBy;
    if (action != null && action.isNotEmpty) params['action'] = action;
    if (from != null && from.isNotEmpty) params['from'] = from;
    if (to != null && to.isNotEmpty) params['to'] = to;

    final response = await _dio.get(
      '${ApiConstant.tasksEndpoint}/history',
      queryParameters: params,
    );
    return TaskHistoryResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /api/v1/tasks/{id}/live-tracking` — one-shot snapshot of the
  /// assignee's current position (initial pin before the socket stream).
  Future<TaskLiveTrackingResponse> getTaskLiveTracking(int id) async {
    final response =
        await _dio.get('${ApiConstant.tasksEndpoint}/$id/live-tracking');
    return TaskLiveTrackingResponse.fromJson(
        response.data as Map<String, dynamic>);
  }
}
