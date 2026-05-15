import 'package:fieldguard/core/services/token_storage.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/login/data/datasource/login_datasource.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_request.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_response.dart';
import 'package:fieldguard/features/auth/login/domain/repository/login_repository.dart';

class LoginRepositoryImpl extends LoginRepository {
  final LoginDataSource _dataSource;

  LoginRepositoryImpl(this._dataSource);

  @override
  Future<Result<LoginResponse>> login(
    String phoneNumber,
    String password,
  ) async {
    final result = await _dataSource.login(
      LoginRequest(phoneNumber: phoneNumber, password: password),
    );

    if (result is Success<LoginResponse>) {
      await TokenStorage.saveTokens(
        accessToken: result.data.accessToken,
        refreshToken: result.data.refreshToken,
      );
    }

    return result;
  }
}
