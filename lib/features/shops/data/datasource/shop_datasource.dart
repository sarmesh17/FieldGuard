import 'package:fieldguard/features/shops/data/dto/create_shop_request.dart';
import 'package:fieldguard/features/shops/data/dto/create_shop_response.dart';
import 'package:fieldguard/features/shops/data/dto/update_shop_visibility_request.dart';

abstract class ShopDataSource {
  Future<CreateShopResponse> createShop(CreateShopRequest request);
  Future<void> updateShopVisibility(
    String shopId,
    UpdateShopVisibilityRequest request,
  );

  /// Permanently deletes a shop. ADMIN only.
  /// `DELETE /api/v1/shops/{id}`.
  Future<void> deleteShop(int id);
}
