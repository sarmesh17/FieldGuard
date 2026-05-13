import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_request.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_response.dart';
import 'package:fieldguard/features/auth/signup/domain/repository/signup_repository.dart';

class SignupUsecase {
  final SignupRepository _repository;
  SignupUsecase(this._repository);

  Future<Result<SignupResponse>> call(SignupRequest request) =>
      _repository.register(request);
}
