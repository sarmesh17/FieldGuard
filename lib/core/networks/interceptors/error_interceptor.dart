import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
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

        final respnse = await Dio().post(
          ApiConstant.baseUrl,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = respnse.data['accessToken'] as String;
        final newRefreshToken = respnse.data['refreshToken'] as String;

        await TokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry the original request with the new access token
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
        return;
      } catch (_) {
        await TokenStorage.clearTokens();
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[HTTP ERR] ${err.type} | ${err.response?.statusCode} | ${err.message}',
      );
    }
    handler.next(err);
  }
}
