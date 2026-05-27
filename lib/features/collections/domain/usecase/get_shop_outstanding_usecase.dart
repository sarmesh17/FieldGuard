import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/domain/repository/collection_repository.dart';

class GetShopOutstandingUsecase {
  final CollectionRepository _repository;
  GetShopOutstandingUsecase(this._repository);

  Future<Result<OutstandingSnapshot>> call(int shopId) =>
      _repository.shopOutstanding(shopId);
}
