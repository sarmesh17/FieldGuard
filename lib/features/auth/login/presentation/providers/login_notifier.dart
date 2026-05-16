import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/services/token_storage.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_response.dart';
import 'package:fieldguard/features/auth/login/domain/usecase/login_usecase.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class LoginNotifier extends StateNotifier<LoginState> {
  final LoginUsecase _loginUsecase;

  LoginNotifier(this._loginUsecase) : super(const LoginChecking()) {
    // Check for existing session on initialization
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      
      if (accessToken != null && accessToken.isNotEmpty) {
        // User has a valid token, create a mock response to set success state
        // The actual user data will be fetched by the app when needed
        final mockResponse = LoginResponse(
          accessToken: accessToken,
          refreshToken: await TokenStorage.getRefreshToken() ?? '',
          user: const LoginUser(
            id: 0,
            name: '',
            role: '',
            companyId: 0,
            employeeCode: '',
          ),
        );
        state = LoginSuccess(mockResponse);
      } else {
        state = const LoginInitial();
      }
    } catch (e) {
      // If there's any error reading tokens, go to initial state
      state = const LoginInitial();
    }
  }

  Future<void> login(String phoneNumber, String password) async {
    state = const LoginLoading();

    final result = await _loginUsecase(phoneNumber, password);

    state = switch (result) {
      Success(:final data) => LoginSuccess(data),
      Failure(:final exception) => LoginFailure(
        exception is AppException ? exception.message : AppStrings.serverError,
      ),
    };
  }

  Future<void> logout() async {
    await TokenStorage.clearTokens();
    state = const LoginInitial();
  }

  void reset() {
    state = const LoginInitial();
  }
}
