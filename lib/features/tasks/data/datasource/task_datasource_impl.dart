import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/features/tasks/data/dto/create_task_request.dart';
import 'package:fieldguard/features/tasks/data/dto/create_task_response.dart';
import 'package:fieldguard/features/tasks/data/dto/task_detail_response.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';

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
}
