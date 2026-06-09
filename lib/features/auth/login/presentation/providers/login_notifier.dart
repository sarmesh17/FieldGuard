import 'dart:convert';

import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/services/auth_event_bus.dart';
import 'package:fieldguard/core/services/push_notification_service.dart';
import 'package:fieldguard/core/services/token_storage.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/approval/data/datasource/company_approval_datasource.dart';
import 'package:fieldguard/features/auth/approval/data/dto/company_approval_response.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_response.dart';
import 'package:fieldguard/features/auth/login/domain/usecase/login_usecase.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class LoginNotifier extends StateNotifier<LoginState> {
  final LoginUsecase _loginUsecase;
  final CompanyApprovalDataSource _approvalDataSource;

  LoginNotifier(this._loginUsecase, this._approvalDataSource)
    : super(const LoginChecking()) {
    AuthEventBus.registerSessionExpiredCallback(_handleSessionExpired);
    _checkExistingSession();
  }

  void _handleSessionExpired() {
    if (mounted) state = const LoginInitial();
  }

  @override
  void dispose() {
    AuthEventBus.unregister();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        final claims = _decodeJwtPayload(accessToken);
        final restoredResponse = LoginResponse(
          accessToken: accessToken,
          refreshToken: await TokenStorage.getRefreshToken() ?? '',
          user: LoginUser(
            id: (claims['userId'] as num?)?.toInt() ?? 0,
            name: '',
            role: (claims['role'] as String?) ?? '',
            companyId: (claims['companyId'] as num?)?.toInt() ?? 0,
            employeeCode: '',
          ),
        );
        // A stored EMPLOYEE token (e.g. signed in before this guard existed)
        // must not silently restore into the admin/manager app.
        if (_isBlockedRole(restoredResponse.user.role)) {
          await TokenStorage.clearTokens();
          state = const LoginInitial();
          return;
        }
        state = await _resolveApproval(restoredResponse);
      } else {
        state = const LoginInitial();
      }
    } catch (e) {
      state = const LoginInitial();
    }
  }

  /// Re-fetches the company approval status from `GET /api/v1/company` and
  /// returns the gated [LoginSuccess]. The access token is attached (and
  /// transparently refreshed if expired) by the auth interceptor, so no manual
  /// refresh is needed here.
  ///
  /// Approval is never read from the token — it is short-lived and carries no
  /// approval claim, so a stale token must not be allowed to unlock the app.
  /// If the fetch fails (e.g. offline) we gate to [ApprovalStatus.unknown],
  /// which the router treats conservatively (the pending screen), never the
  /// dashboard.
  Future<LoginState> _resolveApproval(LoginResponse response) async {
    final result = await _approvalDataSource.getApprovalStatus();
    return switch (result) {
      Success(:final data) => LoginSuccess(
        response,
        approvalStatus: data.approvalStatus,
        rejectionReason: data.rejectionReason,
      ),
      Failure() => LoginSuccess(
        response,
        approvalStatus: ApprovalStatus.unknown,
      ),
    };
  }

  /// This is the managers/admins app — field employees must sign in through the
  /// FieldGuard employee app instead. EMPLOYEE is the only field-level role.
  static bool _isBlockedRole(String role) =>
      role.trim().toUpperCase() == 'EMPLOYEE';

  /// Gates a fresh login on role: an EMPLOYEE is rejected (and the tokens the
  /// repository just saved are cleared) so they can't get past the login screen.
  Future<LoginState> _gateRole(LoginResponse response) async {
    if (_isBlockedRole(response.user.role)) {
      await TokenStorage.clearTokens();
      return const LoginFailure(
        'This app is for managers and admins only. Please use the FieldGuard '
        'employee app to sign in.',
      );
    }
    return _resolveApproval(response);
  }

  /// Re-checks approval for the already-authenticated user. Used by the
  /// pending-approval screen's "Refresh" action so the user can unlock the app
  /// the moment an admin approves them, without logging out and back in.
  Future<void> refreshApprovalStatus() async {
    final current = state;
    if (current is! LoginSuccess) return;
    state = await _resolveApproval(current.response);
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final payload = token.split('.')[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> login(
    String phoneNumber,
    String password, {
    required bool termsAccepted,
    required String termsVersion,
  }) async {
    state = const LoginLoading();

    final result = await _loginUsecase(
      phoneNumber,
      password,
      termsAccepted: termsAccepted,
      termsVersion: termsVersion,
    );

    state = switch (result) {
      Success(:final data) => await _gateRole(data),
      Failure(:final exception) => LoginFailure(
        exception is AppException ? exception.message : AppStrings.serverError,
        rateLimited: exception is RateLimitException,
      ),
    };
  }

  Future<void> logout() async {
    // Drop this device's push token server-side first, while the JWT is still
    // valid (the DELETE is authenticated). Best-effort — never blocks logout.
    await PushNotificationService.instance.unregisterToken();
    await TokenStorage.clearTokens();
    state = const LoginInitial();
  }

  void reset() {
    state = const LoginInitial();
  }
}
