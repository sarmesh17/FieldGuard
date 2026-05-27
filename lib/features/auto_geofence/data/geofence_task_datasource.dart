import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auto_geofence/config/geofence_config.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';

/// Fetches the manager's IN_PROGRESS tasks for the geofence layer.
///
/// Independent of the tasks-feature providers (which drive the task UI) —
/// the geofence service owns its own fetch so detection is never coupled
/// to screen state. Reuses the [TasksListResponse] DTO only as a parser;
/// just the embedded shop coordinates are consumed downstream.
class GeofenceTaskDatasource with ApiRunner {
  final Dio _dio;
  GeofenceTaskDatasource(this._dio);

  Future<Result<List<TaskSummary>>> fetchInProgressTasks() =>
      safeCall(() async {
        final response = await _dio.get(
          ApiConstant.tasksEndpoint,
          queryParameters: {
            'status': 'IN_PROGRESS',
            'limit': GeofenceConfig.taskFetchLimit,
          },
        );
        return TasksListResponse.fromJson(
          response.data as Map<String, dynamic>,
        ).tasks;
      });
}
