sealed class UpdateShopState {
  const UpdateShopState();
}

class UpdateShopInitial extends UpdateShopState {
  const UpdateShopInitial();
}

class UpdateShopLoading extends UpdateShopState {
  const UpdateShopLoading();
}

class UpdateShopSuccess extends UpdateShopState {
  const UpdateShopSuccess();
}

class UpdateShopFailure extends UpdateShopState {
  final String message;

  /// Set when the failure is a phone clash/format error on `contactPhone`
  /// (400 or 409), so the screen can highlight the field inline instead of
  /// (or as well as) showing a snackbar. Null for any other failure.
  final String? phoneError;

  const UpdateShopFailure(this.message, {this.phoneError});
}
