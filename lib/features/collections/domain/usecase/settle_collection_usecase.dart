import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/data/dto/settle_collection_request.dart';
import 'package:fieldguard/features/collections/domain/repository/collection_repository.dart';

class SettleCollectionUsecase {
  final CollectionRepository _repository;
  SettleCollectionUsecase(this._repository);

  Future<Result<CreateCollectionResponse>> call(
    int id,
    SettleCollectionRequest request,
  ) =>
      _repository.settleCollection(id, request);
}
