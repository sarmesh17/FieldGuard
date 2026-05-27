/// Settlement target for a PENDING cheque.
enum SettleStatus {
  cleared('CLEARED'),
  bounced('BOUNCED');

  const SettleStatus(this.wire);
  final String wire;
}

/// Body for `PATCH /api/v1/collections/{id}/settle`.
///
/// Only `method=CHEQUE` + `status=PENDING` rows are settleable (ADMIN/MANAGER).
/// [notes], when present, overwrites the existing notes; when omitted, the
/// previous notes are left untouched — so we only send it when non-empty.
class SettleCollectionRequest {
  final SettleStatus status;
  final String? notes;

  const SettleCollectionRequest({required this.status, this.notes});

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{'status': status.wire};
    if (notes != null && notes!.trim().isNotEmpty) {
      body['notes'] = notes!.trim();
    }
    return body;
  }
}
