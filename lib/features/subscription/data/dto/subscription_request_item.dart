/// Status of a subscription upgrade request.
enum SubscriptionRequestStatus { pending, approved, rejected, unknown }

SubscriptionRequestStatus _statusFrom(Object? raw) {
  switch ((raw as String?)?.toUpperCase()) {
    case 'PENDING':
      return SubscriptionRequestStatus.pending;
    case 'APPROVED':
      return SubscriptionRequestStatus.approved;
    case 'REJECTED':
      return SubscriptionRequestStatus.rejected;
    default:
      return SubscriptionRequestStatus.unknown;
  }
}

/// One subscription upgrade request, returned by `POST .../subscription/request`
/// (wrapped in `{ request: {...} }`) and `GET .../subscription/requests`.
class SubscriptionRequestItem {
  final int id;
  final SubscriptionRequestStatus status;
  final int? amountNpr;
  final int? months;
  final String? paymentProof;
  final String? rejectionReason;
  final DateTime? createdAt;

  const SubscriptionRequestItem({
    required this.id,
    required this.status,
    this.amountNpr,
    this.months,
    this.paymentProof,
    this.rejectionReason,
    this.createdAt,
  });

  factory SubscriptionRequestItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionRequestItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: _statusFrom(json['status']),
      amountNpr: (json['amountNpr'] as num?)?.toInt(),
      months: (json['months'] as num?)?.toInt(),
      paymentProof: json['paymentProof'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  bool get isPending => status == SubscriptionRequestStatus.pending;
  bool get isApproved => status == SubscriptionRequestStatus.approved;
  bool get isRejected => status == SubscriptionRequestStatus.rejected;
}
