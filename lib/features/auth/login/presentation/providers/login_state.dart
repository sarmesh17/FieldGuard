import 'package:fieldguard/features/auth/approval/data/dto/company_approval_response.dart';
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
  const LoginSuccess(this.response, {required this.approvalStatus, this.rejectionReason});

  final LoginResponse response;

  /// Company approval gate. The router uses this to decide whether the user
  /// reaches the dashboard, the pending-approval screen, or the rejected
  /// screen. Re-fetched from `GET /api/v1/company` on every login and
  /// app-open — never derived from the access token.
  final ApprovalStatus approvalStatus;

  /// Set only when [approvalStatus] is [ApprovalStatus.rejected].
  final String? rejectionReason;
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
}

// New state for checking existing session
class LoginChecking extends LoginState {
  const LoginChecking();
}
