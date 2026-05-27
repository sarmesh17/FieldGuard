import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auto_geofence/domain/geofence_visit.dart';

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

  Future<Result<void>> submit(GeofenceVisit visit) => safeCall(() async {
    await _dio.post(
      ApiConstant.geofenceVisitsEndpoint,
      data: visit.toJson(),
    );
  });
}
