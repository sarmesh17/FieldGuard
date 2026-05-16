import 'package:fieldguard/features/shops/domain/models/shop_with_creator.dart';

sealed class ShopsState {
  const ShopsState();
}

class ShopsInitial extends ShopsState {
  const ShopsInitial();
}

class ShopsLoading extends ShopsState {
  const ShopsLoading();
}

class ShopsSuccess extends ShopsState {
  const ShopsSuccess(this.shops);
  final List<ShopWithCreator> shops;
}

class ShopsFailure extends ShopsState {
  final String message;
  const ShopsFailure(this.message);
}
