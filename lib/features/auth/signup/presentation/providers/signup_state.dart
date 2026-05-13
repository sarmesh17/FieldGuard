class SignupState {
  final bool hidePassword;
  final String selectedKey;
  final bool isVerifying;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const SignupState({
    this.hidePassword = true,
    this.selectedKey = '+91',
    this.isVerifying = false,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  SignupState copyWith({
    bool? hidePassword,
    String? selectedKey,
    bool? isVerifying,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return SignupState(
      hidePassword: hidePassword ?? this.hidePassword,
      selectedKey: selectedKey ?? this.selectedKey,
      isVerifying: isVerifying ?? this.isVerifying,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
