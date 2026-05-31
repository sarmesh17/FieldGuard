import '../../../../core/errors/app_exception.dart';
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

  /// Per-field server validation errors (from a 400 `errors[]`). Empty for a
  /// 409 or any failure without per-field detail. The edit screen binds these
  /// to the matching input (e.g. `phoneNumber`, `companyPhone`) and shows
  /// anything unbound as a snackbar.
  final List<FieldError> fieldErrors;

  const ProfileUpdateFailure(this.message, {this.fieldErrors = const []});
}
