import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/live_tracking/data/datasource/tracking_history_datasource.dart';
import 'package:fieldguard/features/live_tracking/data/dto/tracking_history_response.dart';

/// Fetches tracking session summaries and per-session routes for an employee.
///
/// Thin pass-through — business rules (e.g. date-range validation) can be
/// added here later without touching the datasource or UI.
class GetTrackingHistoryUsecase {
  final TrackingHistoryDataSource _dataSource;

  GetTrackingHistoryUsecase(this._dataSource);

  /// Session summaries (optionally filtered by date range).
  Future<Result<TrackingHistoryResponse>> call({
    required int employeeId,
    String? from,
    String? to,
    int limit = 500,
  }) =>
      _dataSource.getTrackingHistory(
        employeeId: employeeId,
        from: from,
        to: to,
        limit: limit,
      );

  /// GPS breadcrumbs for one session (the latest when [sessionId] is null).
  Future<Result<TrackingHistoryResponse>> route({
    required int employeeId,
    int? sessionId,
  }) =>
      _dataSource.getSessionRoute(
        employeeId: employeeId,
        sessionId: sessionId,
      );
}
