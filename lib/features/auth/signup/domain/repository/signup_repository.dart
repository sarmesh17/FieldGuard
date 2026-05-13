import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_request.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_response.dart';

abstract class SignupRepository {
  Future<Result<SignupResponse>> register(SignupRequest request);
}
