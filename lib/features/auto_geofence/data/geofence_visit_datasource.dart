import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auto_geofence/domain/geofence_visit.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';

/// Outcome of one visit POST: success/failure plus the server's updated
/// [task] when the backend auto-completed it on this write. The body is
/// `{ "visit": {...}, "task": {...} }` and the task may be `null` for
/// idempotent duplicates that didn't trigger completion, or when the task
/// is no longer visible to the caller.
typedef SubmitResponse = ({Result<void> result, TaskSummary? task});

/// Sends a completed visit to the backend.
///
/// Uses the app [Dio] (with the auth + error interceptors), so the bearer
/// token is attached, an expired token is refreshed transparently, and a
/// 401 is retried after refresh — the upload survives a token refresh
/// without the queue having to know about auth at all. The backend
/// returns 201 for both the first write and idempotent duplicate retries
/// (deduped on `visitId`), so any 2xx is a success.
class GeofenceVisitDatasource with ApiRunner {
  final Dio _dio;
  GeofenceVisitDatasource(this._dio);

  Future<SubmitResponse> submit(GeofenceVisit visit) async {
    final result = await safeCall<TaskSummary?>(() async {
      final res = await _dio.post(
        ApiConstant.geofenceVisitsEndpoint,
        data: visit.toJson(),
      );
      // Parse the server's returned task — auto-completion fires on the
      // first non-duplicate write, so this is how the app learns the task
      // is now COMPLETED without issuing its own GET. TaskSummary.fromJson
      // is lenient; extra fields on the response are ignored.
      final body = res.data;
      if (body is Map && body['task'] is Map) {
        try {
          return TaskSummary.fromJson(
            Map<String, dynamic>.from(body['task'] as Map),
          );
        } catch (_) {
          return null; // unexpected shape — the 2xx still counts as success
        }
      }
      return null;
    });
    return switch (result) {
      Success(:final data) =>
        (result: const Success<void>(null), task: data),
      Failure(:final exception) =>
        (result: Failure<void>(exception), task: null),
    };
  }
}
