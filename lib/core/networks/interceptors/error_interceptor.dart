import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/services/auth_event_bus.dart';
import 'package:fieldguard/core/services/token_storage.dart';
import 'package:flutter/foundation.dart';

class ErrorInterceptor extends Interceptor {
  final Dio _dio;

  ErrorInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await TokenStorage.getRefreshToken();

        if (refreshToken == null || refreshToken.isEmpty) {
          await _expireSession();
          handler.next(err);
          return;
        }

        final response = await Dio().post(
          ApiConstant.refreshTokenEndpoint, // was: ApiConstant.baseUrl
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'] as String;
        final newRefreshToken = response.data['refreshToken'] as String;

        await TokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
        return;
      } catch (_) {
        await _expireSession();
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[HTTP ERR] ${err.type} | ${err.response?.statusCode} | ${err.message}',
      );
    }
    handler.next(err);
  }

  Future<void> _expireSession() async {
    await TokenStorage.clearTokens();
    AuthEventBus.triggerSessionExpired();
  }
}
