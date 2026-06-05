import 'package:fieldguard/features/collections/data/dto/collections_list_response.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';

/// Active filters for the shop collections list. `shopId` is fixed by the
/// hosting screen; the rest are user-driven. Null = no filter for that field.
class CollectionFilters {
  final String? method; // CASH | CHEQUE
  final String? status; // PENDING | CLEARED | BOUNCED
  final String? from; // ISO date-time (inclusive lower bound)
  final String? to; // ISO date-time (inclusive upper bound)

  const CollectionFilters({this.method, this.status, this.from, this.to});

  CollectionFilters copyWith({
    Object? method = _unset,
    Object? status = _unset,
    Object? from = _unset,
    Object? to = _unset,
  }) {
    return CollectionFilters(
      method: method == _unset ? this.method : method as String?,
      status: status == _unset ? this.status : status as String?,
      from: from == _unset ? this.from : from as String?,
      to: to == _unset ? this.to : to as String?,
    );
  }

  static const _unset = Object();
}

/// Paginated, filterable list state for a single shop's collections.
sealed class CollectionsListState {
  const CollectionsListState();
}

class CollectionsListInitial extends CollectionsListState {
  const CollectionsListInitial();
}

class CollectionsListLoading extends CollectionsListState {
  const CollectionsListLoading();
}

class CollectionsListSuccess extends CollectionsListState {
  final List<CollectionRecord> items;
  final CollectionsSummary summary;
  final CollectionsPagination pagination;
  final CollectionFilters filters;

  /// True while a "load more" page request is in flight (keeps the existing
  /// items on screen with a footer spinner).
  final bool loadingMore;

  const CollectionsListSuccess({
    required this.items,
    required this.summary,
    required this.pagination,
    required this.filters,
    this.loadingMore = false,
  });

  bool get hasMore => pagination.hasMore;

  CollectionsListSuccess copyWith({
    List<CollectionRecord>? items,
    CollectionsSummary? summary,
    CollectionsPagination? pagination,
    CollectionFilters? filters,
    bool? loadingMore,
  }) {
    return CollectionsListSuccess(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      pagination: pagination ?? this.pagination,
      filters: filters ?? this.filters,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class CollectionsListFailure extends CollectionsListState {
  final String message;
  final CollectionFilters filters;
  const CollectionsListFailure(this.message, this.filters);
}
