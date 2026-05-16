import 'dart:convert';

import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/services/auth_event_bus.dart';
import 'package:fieldguard/core/services/token_storage.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_response.dart';
import 'package:fieldguard/features/auth/login/domain/usecase/login_usecase.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class LoginNotifier extends StateNotifier<LoginState> {
  final LoginUsecase _loginUsecase;

  LoginNotifier(this._loginUsecase) : super(const LoginChecking()) {
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
        state = LoginSuccess(restoredResponse);
      } else {
        state = const LoginInitial();
      }
    } catch (e) {
      state = const LoginInitial();
    }
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
      Success(:final data) => LoginSuccess(data),
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
