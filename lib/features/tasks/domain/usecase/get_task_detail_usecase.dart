import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/dto/task_detail_response.dart';
import 'package:fieldguard/features/tasks/domain/repository/tasks_repository.dart';

class GetTaskDetailUsecase {
  final TasksRepository _repository;

  GetTaskDetailUsecase(this._repository);

  Future<Result<TaskDetailResponse>> call(int id) {
    return _repository.getTaskDetail(id);
  }
}
