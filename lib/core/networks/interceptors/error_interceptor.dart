import 'package:dio/dio.dart';
import 'package:fieldguard/core/services/auth_event_bus.dart';
import 'package:fieldguard/core/services/token_storage.dart';
import 'package:fieldguard/core/services/token_refresher.dart';
import 'package:flutter/foundation.dart';

/// Handles 401s by silently refreshing the access token and retrying.
///
/// The session is expired (→ login screen) ONLY when the refresh token is
/// genuinely rejected. A timeout / connection drop while the app was
/// backgrounded does NOT log the user out — the tokens are kept and the
/// next attempt (e.g. on resume) can recover.
class ErrorInterceptor extends Interceptor {
  final Dio _dio;

  /// Marker so a retried request never triggers a second refresh loop.
  static const _retriedFlag = '__fg_retried_after_refresh__';

  ErrorInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    final isUnauthorized = status == 401;
    final isAuthEndpoint =
        path.contains('/auth/refresh-token') || path.contains('/auth/login');
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;

    if (!isUnauthorized || isAuthEndpoint || alreadyRetried) {
      _logError(err);
      return handler.next(err);
    }

    final result = await TokenRefresher.refresh();

    switch (result.outcome) {
      case RefreshOutcome.invalid:
        // Refresh token truly rejected → real expiry.
        await _expireSession();
        _logError(err);
        return handler.next(err);

      case RefreshOutcome.networkError:
        // Transient — keep the user logged in, just surface this error.
        _logError(err);
        return handler.next(err);

      case RefreshOutcome.refreshed:
        try {
          final retryOptions = err.requestOptions
            ..headers['Authorization'] = 'Bearer ${result.accessToken}'
            ..extra[_retriedFlag] = true;
          final retryResponse = await _dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } on DioException catch (retryErr) {
          // Still 401 with a fresh token → session is genuinely gone.
          if (retryErr.response?.statusCode == 401) {
            await _expireSession();
          }
          _logError(retryErr);
          return handler.next(retryErr);
        }
    }
  }

  Future<void> _expireSession() async {
    await TokenStorage.clearTokens();
    AuthEventBus.triggerSessionExpired();
  }

  void _logError(DioException err) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP ERR] ${err.type} | ${err.response?.statusCode} | ${err.message}',
      );
    }
  }
}
