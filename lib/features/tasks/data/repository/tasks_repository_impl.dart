import 'package:dio/dio.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/network_exception_mapper.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/datasource/task_datasource_impl.dart';
import 'package:fieldguard/features/tasks/data/dto/task_detail_response.dart';
import 'package:fieldguard/features/tasks/data/dto/task_history_response.dart';
import 'package:fieldguard/features/tasks/data/dto/task_live_tracking_response.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/tasks/data/dto/update_task_request.dart';
import 'package:fieldguard/features/tasks/data/dto/update_task_response.dart';
import 'package:fieldguard/features/tasks/domain/repository/tasks_repository.dart';

class TasksRepositoryImpl implements TasksRepository {
  final TaskDataSourceImpl _dataSource;

  TasksRepositoryImpl(this._dataSource);

  @override
  Future<Result<TasksListResponse>> getTasks({
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
    try {
      final response = await _dataSource.getTasks(
        page: page,
        limit: limit,
        search: search,
        status: status,
        priority: priority,
        userId: userId,
        managerId: managerId,
        hasManager: hasManager,
        assigneeRole: assigneeRole,
        createdBy: createdBy,
        view: view,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      return Success(response);
    } catch (e) {
      return Failure(ServerException('Failed to load tasks'));
    }
  }

  @override
  Future<Result<TaskDetailResponse>> getTaskDetail(int id) async {
    try {
      final response = await _dataSource.getTaskDetail(id);
      return Success(response);
    } catch (e) {
      return Failure(ServerException('Failed to load task'));
    }
  }

  @override
  Future<Result<UpdateTaskResponse>> updateTask(
    int id,
    UpdateTaskRequest request,
  ) async {
    try {
      final response = await _dataSource.updateTask(id, request);
      return Success(response);
    } on DioException catch (e) {
      // Surface the server's own message — the API deliberately uses
      // 400 (e.g. "changeReason is required") and 403 (EMPLOYEE editing
      // priority/dueDate) here, and the user needs to see why it failed.
      return Failure(NetworkExceptionMapper.map(e));
    } catch (_) {
      return Failure(ServerException('Failed to update task'));
    }
  }

  @override
  Future<Result<TaskHistoryResponse>> getTaskHistory({
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
    try {
      final response = await _dataSource.getTaskHistory(
        taskId: taskId,
        userId: userId,
        managerId: managerId,
        performedBy: performedBy,
        action: action,
        from: from,
        to: to,
        page: page,
        limit: limit,
        sortOrder: sortOrder,
      );
      return Success(response);
    } on DioException catch (e) {
      return Failure(NetworkExceptionMapper.map(e));
    } catch (_) {
      return Failure(ServerException('Failed to load task history'));
    }
  }

  @override
  Future<Result<TaskLiveTrackingResponse>> getTaskLiveTracking(int id) async {
    try {
      final response = await _dataSource.getTaskLiveTracking(id);
      return Success(response);
    } on DioException catch (e) {
      return Failure(NetworkExceptionMapper.map(e));
    } catch (_) {
      return Failure(ServerException('Failed to load live tracking'));
    }
  }
}
