import 'package:fieldguard/features/shops/data/dto/update_shop_request.dart';

abstract class UpdateShopDataSource {
  Future<void> updateShop(int id, UpdateShopRequest request);
}
