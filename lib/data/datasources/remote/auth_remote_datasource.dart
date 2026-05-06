import 'package:dio/dio.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';

/// Contract for remote authentication operations.
abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({
    required String email,
    required String password,
  });
}

/// Dio-based implementation of [AuthRemoteDataSource].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/sign-in',
        data: {'email': email, 'password': password},
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Sign-in failed');
    }
  }
}
