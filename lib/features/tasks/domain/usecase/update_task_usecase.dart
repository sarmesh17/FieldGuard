import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/dto/update_task_request.dart';
import 'package:fieldguard/features/tasks/data/dto/update_task_response.dart';
import 'package:fieldguard/features/tasks/domain/repository/tasks_repository.dart';

class UpdateTaskUsecase {
  final TasksRepository _repository;

  UpdateTaskUsecase(this._repository);

  Future<Result<UpdateTaskResponse>> call(
    int id,
    UpdateTaskRequest request,
  ) {
    return _repository.updateTask(id, request);
  }
}
