/// One in-app notification from `GET /api/v1/notifications`.
class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String body;

  /// Free-form payload. All values are strings (FCM rule), e.g.
  /// `{ "kind": "CHEQUE_RECEIVED", "collectionId": "42", "shopId": "7" }`.
  final Map<String, dynamic> data;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  // Push delivers all data values as strings; in-app JSON keeps numbers. The
  // `?.toString()` normalises both (e.g. taskId 123 or "123" -> "123").
  String? get kind => data['kind']?.toString();
  String? get shopId => data['shopId']?.toString();
  String? get collectionId => data['collectionId']?.toString();
  String? get taskId => data['taskId']?.toString();

  // Collection extras (COLLECTION_RECEIVED / CHEQUE_* ) for the rich tile.
  String? get method => data['method']?.toString();
  String? get amount => data['amount']?.toString();
  String? get outstanding => data['outstanding']?.toString();
  String? get status => data['status']?.toString();

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  NotificationItem markedRead(String at) => NotificationItem(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: true,
        readAt: at,
        createdAt: createdAt,
      );
}

/// Envelope for `GET /api/v1/notifications`.
class NotificationsResponse {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final int total;
  final int page;
  final int limit;

  const NotificationsResponse({
    required this.notifications,
    required this.unreadCount,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      notifications: (json['notifications'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }
}
