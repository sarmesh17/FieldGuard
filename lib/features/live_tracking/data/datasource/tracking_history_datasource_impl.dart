import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/live_tracking/data/datasource/tracking_history_datasource.dart';
import 'package:fieldguard/features/live_tracking/data/dto/tracking_history_response.dart';

class TrackingHistoryDataSourceImpl
    with ApiRunner
    implements TrackingHistoryDataSource {
  final Dio _dio;

  TrackingHistoryDataSourceImpl(this._dio);

  @override
  Future<Result<TrackingHistoryResponse>> getTrackingHistory({
    required int employeeId,
    String? from,
    String? to,
    int limit = 500,
  }) =>
      safeCall(() async {
        final params = <String, dynamic>{'limit': limit};
        if (from != null) params['from'] = from;
        if (to != null) params['to'] = to;

        final response = await _dio.get(
          '${ApiConstant.getEmployeesEndpoint}/$employeeId/history',
          queryParameters: params,
        );
        return TrackingHistoryResponse.fromJson(_asMap(response.data, 'sessions'));
      });

  @override
  Future<Result<TrackingHistoryResponse>> getSessionRoute({
    required int employeeId,
    int? sessionId,
    int limit = 500,
  }) =>
      safeCall(() async {
        final params = <String, dynamic>{'limit': limit};
        if (sessionId != null) params['sessionId'] = sessionId;

        final response = await _dio.get(
          '${ApiConstant.getEmployeesEndpoint}/$employeeId/route',
          queryParameters: params,
        );
        return TrackingHistoryResponse.fromJson(_asMap(response.data, 'route'));
      });

  /// Normalises a response body to a Map. A bare list is wrapped under
  /// [listKey] so the DTO can still find it.
  Map<String, dynamic> _asMap(dynamic data, String listKey) {
    if (data is Map<String, dynamic>) return data;
    if (data is List) return {listKey: data};
    return const {};
  }
}
