import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/datasource/task_datasource_impl.dart';
import 'package:fieldguard/features/tasks/data/dto/task_detail_response.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
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
}
