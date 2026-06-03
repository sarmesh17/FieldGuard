import 'package:fieldguard/core/services/token_storage.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/forgot_password/data/datasource/forgot_password_datasource.dart';
import 'package:fieldguard/features/auth/forgot_password/data/dto/forgot_password_request.dart';
import 'package:fieldguard/features/auth/forgot_password/data/dto/reset_password_request.dart';
import 'package:fieldguard/features/auth/forgot_password/domain/repository/forgot_password_repository.dart';

class ForgotPasswordRepositoryImpl extends ForgotPasswordRepository {
  final ForgotPasswordDataSource _dataSource;

  ForgotPasswordRepositoryImpl(this._dataSource);

  @override
  Future<Result<void>> requestOtp(String phoneNumber) {
    return _dataSource.forgotPassword(
      ForgotPasswordRequest(phoneNumber: phoneNumber),
    );
  }

  @override
  Future<Result<void>> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    final result = await _dataSource.resetPassword(
      ResetPasswordRequest(
        phoneNumber: phoneNumber,
        otp: otp,
        newPassword: newPassword,
      ),
    );

    // The reset invalidates every session server-side; make sure no stale local
    // token survives so the next screen is a clean login.
    if (result is Success<void>) {
      await TokenStorage.clearTokens();
    }

    return result;
  }
}
