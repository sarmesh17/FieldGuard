import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/services/token_storage.dart';
import 'package:flutter/foundation.dart';

enum RefreshOutcome {
  /// New tokens obtained and saved.
  refreshed,

  /// The refresh token itself was rejected (401/403) or missing — this is a
  /// real session expiry; the user must log in again.
  invalid,

  /// Timeout / connection drop / 5xx — transient. Tokens are KEPT so a later
  /// attempt (e.g. on app resume) can succeed. Never log the user out here.
  networkError,
}

class RefreshResult {
  final RefreshOutcome outcome;
  final String? accessToken;
  const RefreshResult(this.outcome, [this.accessToken]);

  bool get ok => outcome == RefreshOutcome.refreshed;
}

/// One place that performs the refresh-token exchange.
///
/// Shared by the Dio [ErrorInterceptor] and the live-tracking socket so that
/// concurrent 401s + a socket reconnect never fire parallel refreshes (the
/// refresh token is single-use — parallel calls would invalidate the session).
class TokenRefresher {
  TokenRefresher._();

  static Completer<RefreshResult>? _inFlight;

  static Future<RefreshResult> refresh() {
    final existing = _inFlight;
    if (existing != null) return existing.future;

    final completer = Completer<RefreshResult>();
    _inFlight = completer;
    _run().then((r) {
      _inFlight = null;
      if (!completer.isCompleted) completer.complete(r);
    });
    return completer.future;
  }

  static Future<RefreshResult> _run() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return const RefreshResult(RefreshOutcome.invalid);
      }

      // Bare Dio: no interceptors → no auth header, no recursion.
      final response = await Dio().post(
        ApiConstant.refreshTokenEndpoint,
        data: {'refreshToken': refreshToken},
      );

      final body = response.data;
      final newAccess = _readToken(body, 'accessToken');
      if (newAccess != null) {
        // Some backends rotate the refresh token, some don't return a new
        // one — fall back to the token we just used so we never wipe it.
        final newRefresh = _readToken(body, 'refreshToken') ?? refreshToken;
        await TokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
        return RefreshResult(RefreshOutcome.refreshed, newAccess);
      }
      // 2xx but we couldn't read a token (contract / envelope drift). This
      // is NOT a session expiry — keep the existing tokens so a later
      // attempt can recover. Logging the user out here would nuke a
      // still-valid session over a parsing quirk.
      if (kDebugMode) {
        debugPrint('[AUTH] refresh 2xx but unparseable body — keeping session');
      }
      return const RefreshResult(RefreshOutcome.networkError);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // Only a rejected refresh token is a true expiry.
      if (code == 401 || code == 403) {
        return const RefreshResult(RefreshOutcome.invalid);
      }
      // Timeouts / connection errors / 5xx → keep tokens, retry later.
      if (kDebugMode) debugPrint('[AUTH] refresh transient failure: ${e.type}');
      return const RefreshResult(RefreshOutcome.networkError);
    } catch (e) {
      if (kDebugMode) debugPrint('[AUTH] refresh unexpected error: $e');
      return const RefreshResult(RefreshOutcome.networkError);
    }
  }

  /// Reads a token by [key] from the refresh response, tolerating either a
  /// flat body (`{ accessToken, ... }`) or one wrapped under `data`
  /// (`{ data: { accessToken, ... } }`). Returns null if absent/empty.
  static String? _readToken(Object? body, String key) {
    if (body is! Map) return null;
    final top = body[key];
    if (top is String && top.isNotEmpty) return top;
    final inner = body['data'];
    if (inner is Map) {
      final nested = inner[key];
      if (nested is String && nested.isNotEmpty) return nested;
    }
    return null;
  }
}
