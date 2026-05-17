import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/services/auth_event_bus.dart';
import 'package:fieldguard/core/services/token_storage.dart';
import 'package:flutter/foundation.dart';

/// Handles 401 responses by silently refreshing the access token and retrying
/// the failed request. Concurrent 401s share a single in-flight refresh so we
/// never burn the (single-use) refresh token via parallel calls.
class ErrorInterceptor extends Interceptor {
  final Dio _dio;

  /// Single in-flight refresh shared across concurrent 401 errors.
  /// Resolves with the new access token, or `null` if refresh failed.
  static Completer<String?>? _refreshCompleter;

  /// Marker placed on a request once it has been retried after a refresh,
  /// so we never enter an infinite refresh-retry loop.
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

    // Only attempt silent refresh on plain 401s for non-auth endpoints that
    // we have not already retried once.
    if (!isUnauthorized || isAuthEndpoint || alreadyRetried) {
      _logError(err);
      return handler.next(err);
    }

    try {
      final newAccessToken = await _refreshAccessToken();

      if (newAccessToken == null) {
        // Refresh token is missing / invalid / server rejected it.
        await _expireSession();
        _logError(err);
        return handler.next(err);
      }

      // Retry the original request with the new token. Mark it so a second
      // 401 does not trigger another refresh attempt.
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken'
        ..extra[_retriedFlag] = true;

      final retryResponse = await _dio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      // The retry itself failed. If it is another 401 we treat the session as
      // truly expired; otherwise just propagate the error.
      if (retryErr.response?.statusCode == 401) {
        await _expireSession();
      }
      _logError(retryErr);
      return handler.next(retryErr);
    } catch (_) {
      await _expireSession();
      _logError(err);
      return handler.next(err);
    }
  }

  /// Performs the token refresh, ensuring only ONE network call happens even
  /// when many requests fail with 401 at the same time.
  Future<String?> _refreshAccessToken() async {
    // A refresh is already in flight – just await its result.
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    String? newAccessToken;
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        newAccessToken = null;
      } else {
        // Fresh Dio instance: no interceptors → no auth header, no recursion.
        final response = await Dio().post(
          ApiConstant.refreshTokenEndpoint,
          data: {'refreshToken': refreshToken},
        );

        final data = response.data;
        if (data is Map) {
          final access = data['accessToken'];
          final refresh = data['refreshToken'];
          if (access is String && access.isNotEmpty &&
              refresh is String && refresh.isNotEmpty) {
            await TokenStorage.saveTokens(
              accessToken: access,
              refreshToken: refresh,
            );
            newAccessToken = access;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH] Silent refresh failed: $e');
      }
      newAccessToken = null;
    } finally {
      _refreshCompleter = null;
      if (!completer.isCompleted) {
        completer.complete(newAccessToken);
      }
    }

    return completer.future;
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
