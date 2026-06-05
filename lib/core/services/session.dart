import 'dart:convert';

import 'package:fieldguard/core/services/token_storage.dart';

/// Reads the signed-in user's identity straight from the access-token
/// claims (the backend already embeds `role` in the JWT — same source the
/// login flow uses to restore a session). No extra storage needed.
class Session {
  Session._();

  static Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final normalized = base64Url.normalize(parts[1]);
      return jsonDecode(utf8.decode(base64Url.decode(normalized)))
          as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Role from the token claims, e.g. `MANAGER` / `ADMIN` / `EMPLOYEE`.
  static Future<String?> role() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    final claims = _decodeJwt(token);
    final r = claims['role'];
    return r is String ? r : null;
  }

  /// True only for managers (case-insensitive).
  static Future<bool> isManager() async {
    final r = await role();
    return r != null && r.toLowerCase() == 'manager';
  }

  /// Signed-in user's id from the `userId` claim, or null if unknown.
  static Future<int?> userId() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    final id = _decodeJwt(token)['userId'];
    return id is int ? id : null;
  }

  /// Company id from the `companyId` claim, or null if unknown. Used as the
  /// `entityId` when requesting a presigned upload URL for company-scoped
  /// assets (e.g. payment screenshots).
  static Future<int?> companyId() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    final id = _decodeJwt(token)['companyId'];
    return id is num ? id.toInt() : null;
  }

  /// Access-token expiry from the `exp` claim, or null if unknown.
  static Future<DateTime?> accessTokenExpiry() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    final exp = _decodeJwt(token)['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    }
    return null;
  }

  /// True if the access token is expired (or within [skew] of expiring).
  /// Returns false when expiry is unknown — let the server be the judge.
  static Future<bool> isAccessTokenExpired({
    Duration skew = const Duration(seconds: 30),
  }) async {
    final exp = await accessTokenExpiry();
    if (exp == null) return false;
    return DateTime.now().toUtc().isAfter(exp.subtract(skew));
  }
}
