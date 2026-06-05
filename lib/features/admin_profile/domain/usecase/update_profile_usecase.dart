import '../../../../core/utils/results.dart';
import '../../data/dto/profile_response.dart';
import '../../data/dto/update_profile_request.dart';
import '../repository/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Result<ProfileResponse>> call(UpdateProfileRequest request) async {
    return await repository.updateProfile(request);
  }
}
