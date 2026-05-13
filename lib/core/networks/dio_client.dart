import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/networks/interceptors/auth_interceptor.dart';
import 'package:fieldguard/core/networks/interceptors/error_interceptor.dart';
import 'package:fieldguard/core/networks/interceptors/logging_interceptor.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  static Dio createDio() {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: ApiConstant.baseUrl,
        connectTimeout: const Duration(seconds: ApiConstant.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConstant.receiveTimeout),
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(dio),
      if (kDebugMode) LoggingInterceptor(),
    ]);

    return dio;
  }
}
