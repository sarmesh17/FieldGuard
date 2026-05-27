import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/live_tracking/data/dto/tracking_history_response.dart';

/// Contract for fetching an employee's tracking session history.
abstract class TrackingHistoryDataSource {
  /// `GET /api/v1/employees/{employeeId}/history`
  Future<Result<TrackingHistoryResponse>> getTrackingHistory({
    required int employeeId,
    String? from,
    String? to,
    int? sessionId,
    int limit = 500,
  });
}
