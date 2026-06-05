import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/notifications/data/notifications_response.dart';

/// In-app notification center. Auth required; only an APPROVED company gets
/// data here (a pending company will 403 — token-register does not need this).
class NotificationsDatasource with ApiRunner {
  final Dio _dio;
  NotificationsDatasource(this._dio);

  /// `GET /api/v1/notifications?page=&limit=&unreadOnly=`
  Future<Result<NotificationsResponse>> fetch({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) =>
      safeCall(() async {
        final res = await _dio.get(
          ApiConstant.notificationsEndpoint,
          queryParameters: {
            'page': page,
            'limit': limit,
            'unreadOnly': unreadOnly,
          },
        );
        return NotificationsResponse.fromJson(res.data as Map<String, dynamic>);
      });

  /// `PATCH /api/v1/notifications/:id/read` — marks one as read (no "mark all").
  Future<Result<void>> markRead(int id) => safeCall(() async {
        await _dio.patch('${ApiConstant.notificationsEndpoint}/$id/read');
      });
}
