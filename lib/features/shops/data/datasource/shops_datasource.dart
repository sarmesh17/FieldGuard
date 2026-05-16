import 'package:fieldguard/features/shops/data/dto/shops_hierarchy_response.dart';

abstract class ShopsDataSource {
  Future<ShopsHierarchyResponse> getShopsHierarchy();
}
