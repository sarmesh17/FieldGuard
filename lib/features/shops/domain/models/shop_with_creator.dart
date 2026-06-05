import 'package:fieldguard/features/shops/data/dto/shops_hierarchy_response.dart';

class ShopWithCreator {
  final Shop shop;
  final String creatorName;
  final String creatorRole; // 'Admin', 'Manager', 'Employee'
  final String creatorCode;

  ShopWithCreator({
    required this.shop,
    required this.creatorName,
    required this.creatorRole,
    required this.creatorCode,
  });
}
