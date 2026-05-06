import '../../models/user_model.dart';

/// Contract for local (cached) authentication operations.
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();
}

/// In-memory implementation of [AuthLocalDataSource].
/// Replace with SharedPreferences / Hive / etc. as needed.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  UserModel? _cachedUser;

  @override
  Future<void> cacheUser(UserModel user) async {
    _cachedUser = user;
  }

  @override
  Future<UserModel?> getCachedUser() async {
    return _cachedUser;
  }

  @override
  Future<void> clearUser() async {
    _cachedUser = null;
  }
}
