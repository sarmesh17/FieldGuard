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
    // Public auth endpoints: no token to attach and no point pre-refreshing one.
    // forgot-/reset-password are reached while logged out, so any stale token
    // must not trigger a refresh attempt here.
    final isAuthEndpoint =
        path.contains('/auth/refresh-token') ||
        path.contains('/auth/login') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password');

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
