import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/live_tracking/data/datasource/tracking_history_datasource.dart';
import 'package:fieldguard/features/live_tracking/data/dto/tracking_history_response.dart';

/// Fetches tracking session history for a field employee.
///
/// Thin pass-through — business rules (e.g. date-range validation) can be
/// added here later without touching the datasource or UI.
class GetTrackingHistoryUsecase {
  final TrackingHistoryDataSource _dataSource;

  GetTrackingHistoryUsecase(this._dataSource);

  Future<Result<TrackingHistoryResponse>> call({
    required int employeeId,
    String? from,
    String? to,
    int? sessionId,
    int limit = 500,
  }) =>
      _dataSource.getTrackingHistory(
        employeeId: employeeId,
        from: from,
        to: to,
        sessionId: sessionId,
        limit: limit,
      );
}
