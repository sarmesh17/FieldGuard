import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/dto/task_live_tracking_response.dart';
import 'package:fieldguard/features/tasks/domain/repository/tasks_repository.dart';

class GetTaskLiveTrackingUsecase {
  final TasksRepository _repository;

  GetTaskLiveTrackingUsecase(this._repository);

  Future<Result<TaskLiveTrackingResponse>> call(int id) {
    return _repository.getTaskLiveTracking(id);
  }
}
