import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true, // Automatically reset storage on decryption errors
    ),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      // If write fails due to encryption issues, clear and retry
      await _handleStorageError();
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      // If read fails due to decryption issues, clear corrupted data
      await _handleStorageError();
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      // If read fails due to decryption issues, clear corrupted data
      await _handleStorageError();
      return null;
    }
  }

  static Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      // If delete fails, try to delete all
      await _handleStorageError();
    }
  }

  /// Handle storage errors by clearing all data
  static Future<void> _handleStorageError() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      // Silently fail - storage will be reset on next access
    }
  }
}
