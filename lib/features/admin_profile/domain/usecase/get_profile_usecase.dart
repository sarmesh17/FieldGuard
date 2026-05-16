import '../../../../core/utils/results.dart';
import '../../data/dto/profile_response.dart';
import '../repository/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<Result<ProfileResponse>> call() async {
    return await repository.getProfile();
  }
}
