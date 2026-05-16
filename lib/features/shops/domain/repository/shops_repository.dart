import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/shops/domain/models/shop_with_creator.dart';

abstract class ShopsRepository {
  Future<Result<List<ShopWithCreator>>> getShopsWithCreators();
}
