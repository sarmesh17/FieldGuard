import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/collections_list_response.dart';
import 'package:fieldguard/features/collections/domain/repository/collection_repository.dart';

class ListCollectionsUsecase {
  final CollectionRepository _repository;
  ListCollectionsUsecase(this._repository);

  Future<Result<CollectionsListResponse>> call({
    int? shopId,
    String? method,
    String? status,
    int? collectedBy,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) =>
      _repository.listCollections(
        shopId: shopId,
        method: method,
        status: status,
        collectedBy: collectedBy,
        from: from,
        to: to,
        page: page,
        limit: limit,
      );
}
