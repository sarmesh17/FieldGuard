import '../../data/dto/profile_response.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileSuccess extends ProfileState {
  final ProfileResponse profile;
  const ProfileSuccess(this.profile);
}

class ProfileFailure extends ProfileState {
  final String message;
  const ProfileFailure(this.message);
}

class ProfileUpdating extends ProfileState {
  const ProfileUpdating();
}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileResponse profile;
  const ProfileUpdateSuccess(this.profile);
}

class ProfileUpdateFailure extends ProfileState {
  final String message;
  const ProfileUpdateFailure(this.message);
}
