import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/sign_in_usecase.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class LoginState {
  final bool hidePassword;
  final bool isLoading;
  final String? errorMessage;
  final User? user;

  const LoginState({
    this.hidePassword = true,
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  LoginState copyWith({
    bool? hidePassword,
    bool? isLoading,
    String? errorMessage,
    User? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return LoginState(
      hidePassword: hidePassword ?? this.hidePassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      user: clearUser ? null : user ?? this.user,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LoginNotifier extends Notifier<LoginState> {
  late final SignInUseCase _signInUseCase;

  @override
  LoginState build() {
    _signInUseCase = ref.read(signInUseCaseProvider);
    return const LoginState();
  }

  void togglePasswordVisibility() {
    state = state.copyWith(hidePassword: !state.hidePassword);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _signInUseCase(email: email, password: password);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        user: user,
      ),
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);
