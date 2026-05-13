import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/login/data/datasource/login_datasource.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_request.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_response.dart';

class LoginDatasourceImpl extends LoginDataSource with ApiRunner {
  final Dio _dio;

  LoginDatasourceImpl(this._dio);

  @override
  Future<Result<LoginResponse>> login(LoginRequest request) =>
      safeCall(() async {
        final response = await _dio.post(
          ApiConstant.loginEndpoint,
          data: request.toJson(),
        );
        return LoginResponse.fromJson(response.data as Map<String, dynamic>);
      });
}
