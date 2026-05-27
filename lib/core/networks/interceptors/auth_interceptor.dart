import 'package:dio/dio.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/services/token_refresher.dart';
import 'package:fieldguard/core/services/token_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final isAuthEndpoint =
        path.contains('/auth/refresh-token') || path.contains('/auth/login');

    // Proactively refresh an access token that has already expired instead
    // of firing a request that is guaranteed to 401. This is what keeps a
    // user who left the app idle (the access token is short-lived) from
    // being bounced to the login screen on their next action — the reactive
    // 401 path in ErrorInterceptor stays only as a backstop.
    if (!isAuthEndpoint && await Session.isAccessTokenExpired()) {
      await TokenRefresher.refresh();
    }

    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }
}
