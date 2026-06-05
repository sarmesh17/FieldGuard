import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_request.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/domain/repository/collection_repository.dart';

class RecordCollectionUsecase {
  final CollectionRepository _repository;
  RecordCollectionUsecase(this._repository);

  Future<Result<CreateCollectionResponse>> call(
    CreateCollectionRequest request,
  ) =>
      _repository.recordCollection(request);
}
