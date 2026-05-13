import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/login/domain/usecase/login_usecase.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class LoginNotifier extends StateNotifier<LoginState> {
  final LoginUsecase _loginUsecase;

  LoginNotifier(this._loginUsecase) : super(const LoginInitial());

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

  void reset() {
    state = const LoginInitial();
  }
}
