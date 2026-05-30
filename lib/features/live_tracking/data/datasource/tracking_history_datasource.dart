import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/live_tracking/data/dto/tracking_history_response.dart';

/// Contract for fetching an employee's tracking sessions and a session route.
abstract class TrackingHistoryDataSource {
  /// `GET /api/v1/employees/{employeeId}/history` — session summaries.
  Future<Result<TrackingHistoryResponse>> getTrackingHistory({
    required int employeeId,
    String? from,
    String? to,
    int limit = 500,
  });

  /// `GET /api/v1/employees/{employeeId}/route` — GPS breadcrumbs for one
  /// session (the latest session when [sessionId] is null), ascending by time.
  Future<Result<TrackingHistoryResponse>> getSessionRoute({
    required int employeeId,
    int? sessionId,
    int limit = 500,
  });
}
