/// Cancel reason values accepted by the PATCH /api/v1/tasks/:id endpoint.
///
/// Rules enforced by the server (and mirrored in the cancel UI):
///  - [shopClosed], [shopRelocated], [shopPermanentlyClosed], [shopNotFound]:
///    `cancelImage` is required; `changeReason` is optional.
///  - [other]: `cancelImage` must NOT be sent; `changeReason` is required.
enum CancelReason {
  shopClosed('SHOP_CLOSED', 'Shop Closed'),
  shopRelocated('SHOP_RELOCATED', 'Shop Relocated'),
  shopPermanentlyClosed('SHOP_PERMANENTLY_CLOSED', 'Shop Permanently Closed'),
  shopNotFound('SHOP_NOT_FOUND', 'Shop Not Found'),
  other('OTHER', 'Other');

  final String value;
  final String label; // full label, used in cancelled-state display
  const CancelReason(this.value, this.label);

  // Abbreviated label for chip buttons in the update sheet
  String get chipLabel => switch (this) {
        shopClosed => 'Shop Closed',
        shopRelocated => 'Shop Relocated',
        shopPermanentlyClosed => 'Perm. Closed',
        shopNotFound => 'Not Found',
        other => 'Other',
      };

  bool get requiresPhoto => this != CancelReason.other;
  bool get requiresChangeReason => this == CancelReason.other;

  static CancelReason? fromString(String? s) {
    if (s == null) return null;
    for (final r in values) {
      if (r.value == s) return r;
    }
    return null;
  }
}

/// Body for `PATCH /api/v1/tasks/{id}`.
///
/// Every field is optional — this is a partial update. Per the API:
///
///  * CANCELLED: [cancelReason] is always required.
///    - Shop-based reasons: [cancelImage] (S3 key) also required.
///    - OTHER: [changeReason] required; [cancelImage] must not be sent.
///  * Reopening (`IN_PROGRESS` → `PENDING`): [changeReason] is required.
///  * [priority] and [dueDate] are ADMIN/MANAGER only — 403 if sent by EMPLOYEE.
class UpdateTaskRequest {
  final String? status;
  final String? remarks;
  final String? priority;
  final String? dueDate; // ISO-8601, e.g. 2026-05-18T07:08:01.140Z
  final String? changeReason;
  final String? cancelReason;
  final String? cancelImage; // S3 key, e.g. companies/5/cancel/shop_42_abc.jpg

  const UpdateTaskRequest({
    this.status,
    this.remarks,
    this.priority,
    this.dueDate,
    this.changeReason,
    this.cancelReason,
    this.cancelImage,
  });

  /// Only non-null fields are emitted so we never overwrite a value the
  /// caller didn't intend to touch.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (status != null) map['status'] = status;
    if (remarks != null) map['remarks'] = remarks;
    if (priority != null) map['priority'] = priority;
    if (dueDate != null) map['dueDate'] = dueDate;
    if (changeReason != null) map['changeReason'] = changeReason;
    if (cancelReason != null) map['cancelReason'] = cancelReason;
    if (cancelImage != null) map['cancelImage'] = cancelImage;
    return map;
  }

  /// True when there is nothing to send — lets callers avoid a pointless
  /// round-trip (the server would 400 on an empty body anyway).
  bool get isEmpty => toJson().isEmpty;
}
