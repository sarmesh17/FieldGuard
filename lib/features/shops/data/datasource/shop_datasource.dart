import 'package:fieldguard/features/shops/data/dto/create_shop_request.dart';
import 'package:fieldguard/features/shops/data/dto/create_shop_response.dart';

abstract class ShopDataSource {
  Future<CreateShopResponse> createShop(CreateShopRequest request);
}
