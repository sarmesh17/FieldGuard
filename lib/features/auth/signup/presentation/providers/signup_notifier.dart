import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_request.dart';
import 'package:fieldguard/features/auth/signup/domain/usecase/signup_usecase.dart';
import 'package:fieldguard/features/auth/signup/presentation/providers/signup_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class SignupNotifier extends StateNotifier<SignupState> {
  final SignupUsecase _signupUsecase;

  SignupNotifier(this._signupUsecase) : super(const SignupState());

  final Map<String, String> images = {
    '+91': 'https://flagcdn.com/w40/in.png',
    '+1': 'https://flagcdn.com/w40/us.png',
    '+44': 'https://flagcdn.com/w40/gb.png',
  };

  void togglePasswordVisibility() {
    state = state.copyWith(hidePassword: !state.hidePassword);
  }

  void setSelectedCountry(String key) {
    state = state.copyWith(selectedKey: key);
  }

  void setVerificationLoading(bool value) {
    state = state.copyWith(isVerifying: value);
  }

  Future<void> register({
    required String companyName,
    required String panNumber,
    required String adminName,
    required String phoneNumber,
    required String password,
    required String citizenshipImagePath,
    required String registrationDocPath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final request = SignupRequest(
      companyName: companyName,
      panNumber: panNumber,
      adminName: adminName,
      phoneNumber: phoneNumber,
      password: password,
      citizenshipImagePath: citizenshipImagePath,
      registrationDocPath: registrationDocPath,
    );

    final result = await _signupUsecase(request);

    state = switch (result) {
      Success() => state.copyWith(isLoading: false, isSuccess: true),
      Failure(:final exception) => state.copyWith(
        isLoading: false,
        errorMessage: exception is AppException
            ? exception.message
            : AppStrings.serverError,
      ),
    };
  }
}
