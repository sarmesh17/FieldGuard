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
  const UpdateShopFailure(this.message);
}
