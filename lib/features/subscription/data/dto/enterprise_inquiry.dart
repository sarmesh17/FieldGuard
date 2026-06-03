/// Status of an ENTERPRISE "Talk to us" call request.
///
/// Flow: PENDING (company submits) → CONTACTED (our team called) → CLOSED
/// (deal done / dropped). Only PENDING blocks a new submit (one at a time).
enum EnterpriseInquiryStatus { pending, contacted, closed, unknown }

EnterpriseInquiryStatus _statusFrom(Object? raw) {
  switch ((raw as String?)?.toUpperCase()) {
    case 'PENDING':
      return EnterpriseInquiryStatus.pending;
    case 'CONTACTED':
      return EnterpriseInquiryStatus.contacted;
    case 'CLOSED':
      return EnterpriseInquiryStatus.closed;
    default:
      return EnterpriseInquiryStatus.unknown;
  }
}

/// One ENTERPRISE call-request lead, returned by
/// `POST .../subscription/enterprise-inquiry` (wrapped in `{ inquiry: {...} }`)
/// and `GET .../subscription/enterprise-inquiries` (newest first).
class EnterpriseInquiry {
  final int id;
  final String contactPhone;
  final int? expectedStaffCount;
  final String? message;
  final EnterpriseInquiryStatus status;

  /// Internal note set by the platform admin after handling — usually null
  /// while PENDING.
  final String? adminNote;
  final DateTime? handledAt;
  final DateTime? createdAt;

  const EnterpriseInquiry({
    required this.id,
    required this.contactPhone,
    this.expectedStaffCount,
    this.message,
    required this.status,
    this.adminNote,
    this.handledAt,
    this.createdAt,
  });

  factory EnterpriseInquiry.fromJson(Map<String, dynamic> json) {
    return EnterpriseInquiry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      contactPhone: (json['contactPhone'] as String?) ?? '',
      expectedStaffCount: (json['expectedStaffCount'] as num?)?.toInt(),
      message: json['message'] as String?,
      status: _statusFrom(json['status']),
      adminNote: json['adminNote'] as String?,
      handledAt: _parseDate(json['handledAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  bool get isPending => status == EnterpriseInquiryStatus.pending;
  bool get isContacted => status == EnterpriseInquiryStatus.contacted;
  bool get isClosed => status == EnterpriseInquiryStatus.closed;
}

DateTime? _parseDate(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
