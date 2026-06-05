import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/network_exception_mapper.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/forgot_password/data/datasource/forgot_password_datasource.dart';
import 'package:fieldguard/features/auth/forgot_password/data/dto/forgot_password_request.dart';
import 'package:fieldguard/features/auth/forgot_password/data/dto/reset_password_request.dart';

class ForgotPasswordDatasourceImpl extends ForgotPasswordDataSource
    with ApiRunner {
  final Dio _dio;

  ForgotPasswordDatasourceImpl(this._dio);

  @override
  Future<Result<void>> forgotPassword(ForgotPasswordRequest request) =>
      safeCall(() async {
        await _dio.post(
          ApiConstant.forgotPasswordEndpoint,
          data: request.toJson(),
        );
      });

  @override
  Future<Result<void>> resetPassword(ResetPasswordRequest request) async {
    try {
      await _dio.post(
        ApiConstant.resetPasswordEndpoint,
        data: request.toJson(),
      );
      return const Success(null);
    } on DioException catch (e) {
      // A 401 here is a bad/expired OTP or "too many incorrect attempts" — not a
      // session problem. The actionable text lives in the response body, so
      // surface it verbatim rather than the generic credentials message the
      // shared mapper produces for every 401.
      if (e.response?.statusCode == 401) {
        final message =
            _bodyMessage(e.response?.data) ?? 'Invalid or expired reset code';
        return Failure(UnauthorizedException(message));
      }
      // 400 (validation), 429 (rate limit) and transport errors keep the
      // standard mapping so per-field errors and rate-limit warnings flow
      // through unchanged.
      return Failure(NetworkExceptionMapper.map(e));
    } on AppException catch (e) {
      return Failure(e);
    } catch (_) {
      return Failure(const ServerException(AppStrings.serverError));
    }
  }

  static String? _bodyMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }
}
