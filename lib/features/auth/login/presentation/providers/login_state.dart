import 'package:fieldguard/features/auth/login/data/dto/login_response.dart';

sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess(this.response);
  final LoginResponse response;
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
}

// New state for checking existing session
class LoginChecking extends LoginState {
  const LoginChecking();
}
