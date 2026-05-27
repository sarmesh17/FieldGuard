import 'dart:convert';

import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/services/auth_event_bus.dart';
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

  Future<void> login(String phoneNumber, String password) async {
    state = const LoginLoading();

    final result = await _loginUsecase(phoneNumber, password);

    state = switch (result) {
      Success(:final data) => await _resolveApproval(data),
      Failure(:final exception) => LoginFailure(
        exception is AppException ? exception.message : AppStrings.serverError,
      ),
    };
  }

  Future<void> logout() async {
    await TokenStorage.clearTokens();
    state = const LoginInitial();
  }

  void reset() {
    state = const LoginInitial();
  }
}
