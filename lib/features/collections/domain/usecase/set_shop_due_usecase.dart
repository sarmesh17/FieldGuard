import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/data/dto/set_shop_due_request.dart';
import 'package:fieldguard/features/collections/domain/repository/collection_repository.dart';

class SetShopDueUsecase {
  final CollectionRepository _repository;
  SetShopDueUsecase(this._repository);

  Future<Result<OutstandingSnapshot>> call(
    int shopId,
    SetShopDueRequest request,
  ) =>
      _repository.setShopDue(shopId, request);
}
