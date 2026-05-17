import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupState {
  final bool hidePassword;
  final String selectedKey;
  final String selectedRole;
  final bool isVerifying;

  const SignupState({
    this.hidePassword = true,
    this.selectedKey = "+977",
    this.selectedRole = "Admin",
    this.isVerifying = false,
  });

  SignupState copyWith({
    bool? hidePassword,
    String? selectedKey,
    String? selectedRole,
    bool? isVerifying,
  }) {
    return SignupState(
      hidePassword: hidePassword ?? this.hidePassword,
      selectedKey: selectedKey ?? this.selectedKey,
      selectedRole: selectedRole ?? this.selectedRole,
      isVerifying: isVerifying ?? this.isVerifying,
    );
  }
}

class SignupNotifier extends Notifier<SignupState> {
  final Map<String, String> images = {
    "+91": "https://www.mapsofindia.com/maps/india/india-flag-a4.jpg",
    "+880":
        "https://cdn.britannica.com/67/6267-050-8A26DFEE/Flag-Bangladesh.jpg",
    "+977": "http://www.pngmart.com/files/10/Nepal-Flag-PNG-HD.png",
  };

  @override
  SignupState build() {
    return const SignupState();
  }

  void togglePasswordVisibility() {
    state = state.copyWith(hidePassword: !state.hidePassword);
  }

  void setSelectedCountry(String key) {
    state = state.copyWith(selectedKey: key);
  }

  void setRole(String role) {
    state = state.copyWith(selectedRole: role);
  }

  void setVerificationLoading(bool value) {
    state = state.copyWith(isVerifying: value);
  }
}

final signupNotifierProvider = NotifierProvider<SignupNotifier, SignupState>(
  SignupNotifier.new,
);
