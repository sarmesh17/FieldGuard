import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_request.dart';
import 'package:fieldguard/features/auth/signup/domain/models/registration_progress.dart';
import 'package:fieldguard/features/auth/signup/domain/usecase/signup_usecase.dart';
import 'package:fieldguard/features/auth/signup/presentation/providers/signup_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class SignupNotifier extends StateNotifier<SignupState> {
  final SignupUsecase _signupUsecase;

  SignupNotifier(this._signupUsecase) : super(const SignupState());

  final Map<String, String> images = {
    '+977': 'https://flagcdn.com/w40/np.png',
    '+1': 'https://flagcdn.com/w40/us.png',
    '+44': 'https://flagcdn.com/w40/gb.png',
  };

  void togglePasswordVisibility() {
    state = state.copyWith(hidePassword: !state.hidePassword);
  }

  void setSelectedCountry(String key) {
    state = state.copyWith(selectedKey: key);
  }

  Future<void> register({
    required String companyName,
    required String companyEmail,
    required String companyPhone,
    required String panNumber,
    required String adminName,
    required String phoneNumber,
    required String password,
    required String citizenshipImagePath,
    required String registrationDocPath,
    required bool termsAccepted,
    required String termsVersion,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearStatus: true);

    final request = SignupRequest(
      companyName: companyName,
      companyEmail: companyEmail,
      companyPhone: companyPhone,
      panNumber: panNumber,
      adminName: adminName,
      phoneNumber: phoneNumber,
      password: password,
      termsAccepted: termsAccepted,
      termsVersion: termsVersion,
    );

    final result = await _signupUsecase(
      request: request,
      citizenshipImagePath: citizenshipImagePath,
      legalDocumentPath: registrationDocPath,
      // Resume from where the last attempt left off, if any.
      progress: state.progress ?? const RegistrationProgress(),
      onStatus: (status) {
        if (mounted) state = state.copyWith(statusMessage: status);
      },
      onProgress: (progress) {
        // Keep the latest progress in state so a failed attempt can be
        // retried from its failed step instead of re-registering.
        if (mounted) state = state.copyWith(progress: progress);
      },
    );

    state = switch (result) {
      Success() => state.copyWith(
        isLoading: false,
        isSuccess: true,
        clearStatus: true,
        clearProgress: true,
      ),
      Failure(:final exception) => state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: exception is AppException
            ? exception.message
            : AppStrings.serverError,
      ),
    };
  }
}
