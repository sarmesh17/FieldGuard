import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';

/// Response for `GET /api/v1/collections`. Reuses [CollectionRecord] (identical
/// projection to the POST response) plus a filter-aware [summary] and
/// [pagination].
class CollectionsListResponse {
  final List<CollectionRecord> collections;
  final CollectionsSummary summary;
  final CollectionsPagination pagination;

  const CollectionsListResponse({
    required this.collections,
    required this.summary,
    required this.pagination,
  });

  factory CollectionsListResponse.fromJson(Map<String, dynamic> json) {
    return CollectionsListResponse(
      collections: (json['collections'] as List<dynamic>? ?? const [])
          .map((e) => CollectionRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: CollectionsSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      pagination: CollectionsPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// Totals across the WHOLE filtered set (not just the current page). All values
/// are Decimal strings; default to "0" when no rows match. Filter-aware — e.g.
/// with `method=CHEQUE` these reflect only cheque rows.
class CollectionsSummary {
  final String cleared;
  final String pending;
  final String bounced;

  const CollectionsSummary({
    required this.cleared,
    required this.pending,
    required this.bounced,
  });

  factory CollectionsSummary.fromJson(Map<String, dynamic> json) {
    return CollectionsSummary(
      cleared: json['cleared']?.toString() ?? '0',
      pending: json['pending']?.toString() ?? '0',
      bounced: json['bounced']?.toString() ?? '0',
    );
  }
}

class CollectionsPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const CollectionsPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory CollectionsPagination.fromJson(Map<String, dynamic> json) {
    return CollectionsPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
