import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/tasks/domain/repository/tasks_repository.dart';

class GetTasksUsecase {
  final TasksRepository _repository;

  GetTasksUsecase(this._repository);

  Future<Result<TasksListResponse>> call({
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
  }) {
    return _repository.getTasks(
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
  }
}
