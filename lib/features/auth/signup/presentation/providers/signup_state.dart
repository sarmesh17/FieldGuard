import 'package:fieldguard/features/auth/signup/domain/models/registration_progress.dart';

class SignupState {
  final bool hidePassword;
  final String selectedKey;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final String? statusMessage;

  /// Progress of an in-flight (or last failed) registration. Retained on
  /// failure so the next attempt resumes from the failed step; cleared on
  /// success. Null before the first attempt.
  final RegistrationProgress? progress;

  const SignupState({
    this.hidePassword = true,
    this.selectedKey = '+977',
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.statusMessage,
    this.progress,
  });

  SignupState copyWith({
    bool? hidePassword,
    String? selectedKey,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    String? statusMessage,
    RegistrationProgress? progress,
    bool clearError = false,
    bool clearStatus = false,
    bool clearProgress = false,
  }) {
    return SignupState(
      hidePassword: hidePassword ?? this.hidePassword,
      selectedKey: selectedKey ?? this.selectedKey,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      statusMessage: clearStatus ? null : statusMessage ?? this.statusMessage,
      progress: clearProgress ? null : progress ?? this.progress,
    );
  }
}
