import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/shops/domain/models/shop_with_creator.dart';
import 'package:fieldguard/features/shops/domain/repository/shops_repository.dart';

class GetShopsUsecase {
  final ShopsRepository _repository;

  GetShopsUsecase(this._repository);

  Future<Result<List<ShopWithCreator>>> call() async {
    return await _repository.getShopsWithCreators();
  }
}
