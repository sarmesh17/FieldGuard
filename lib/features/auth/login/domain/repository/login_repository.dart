import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_request.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_response.dart';

abstract class LoginRepository {
  Future<Result<LoginResponse>> login(String phoneNumber, String password);
}
