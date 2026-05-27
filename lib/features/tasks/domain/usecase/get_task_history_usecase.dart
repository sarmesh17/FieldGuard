import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/dto/task_history_response.dart';
import 'package:fieldguard/features/tasks/domain/repository/tasks_repository.dart';

class GetTaskHistoryUsecase {
  final TasksRepository _repository;

  GetTaskHistoryUsecase(this._repository);

  Future<Result<TaskHistoryResponse>> call({
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
  }) {
    return _repository.getTaskHistory(
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
  }
}
