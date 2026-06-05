/// Parsed `GET /api/v1/company/subscription` payload: the company's current
/// plan + seat usage, the catalogue of available plans, and the shared payment
/// QR details.
///
/// Throughout, a `null` limit means **unlimited** (ENTERPRISE), not zero — the
/// UI renders those as "Unlimited".
class SubscriptionResponse {
  final CurrentSubscription subscription;
  final List<PlanOption> plans;
  final PaymentInfo? payment;

  const SubscriptionResponse({
    required this.subscription,
    required this.plans,
    this.payment,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    final plansJson = json['plans'];
    return SubscriptionResponse(
      subscription: CurrentSubscription.fromJson(
        (json['subscription'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      plans: plansJson is List
          ? plansJson
              .whereType<Map>()
              .map((e) => PlanOption.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
      payment: json['payment'] is Map
          ? PaymentInfo.fromJson(
              (json['payment'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class CurrentSubscription {
  final String plan; // FREE / PRO / ENTERPRISE
  final int priceNpr;
  final String? billing; // null / "monthly" / "custom"
  final DateTime? expiresAt;
  final bool expired;

  /// null = unlimited.
  final int? staffSeatLimit;
  final int staffUsed;

  /// null = unlimited.
  final int? staffRemaining;

  /// null = unlimited.
  final int? totalMemberLimit;

  final bool canAddStaff;

  const CurrentSubscription({
    required this.plan,
    required this.priceNpr,
    required this.billing,
    required this.expiresAt,
    required this.expired,
    required this.staffSeatLimit,
    required this.staffUsed,
    required this.staffRemaining,
    required this.totalMemberLimit,
    required this.canAddStaff,
  });

  factory CurrentSubscription.fromJson(Map<String, dynamic> json) {
    return CurrentSubscription(
      plan: (json['plan'] as String?) ?? 'FREE',
      priceNpr: (json['priceNpr'] as num?)?.toInt() ?? 0,
      billing: json['billing'] as String?,
      expiresAt: _parseDate(json['expiresAt']),
      expired: json['expired'] == true,
      staffSeatLimit: (json['staffSeatLimit'] as num?)?.toInt(),
      staffUsed: (json['staffUsed'] as num?)?.toInt() ?? 0,
      staffRemaining: (json['staffRemaining'] as num?)?.toInt(),
      totalMemberLimit: (json['totalMemberLimit'] as num?)?.toInt(),
      canAddStaff: json['canAddStaff'] == true,
    );
  }

  bool get isUnlimitedStaff => staffSeatLimit == null;
}

class PlanOption {
  final String code; // FREE / PRO / ENTERPRISE

  /// null for ENTERPRISE (custom pricing).
  final int? priceNpr;
  final String? billing; // null / "monthly" / "custom"

  /// null = unlimited.
  final int? staffSeats;

  /// null = unlimited.
  final int? totalMembers;

  /// When true, show "Talk to us" instead of a pay/upgrade button.
  final bool contactSales;

  const PlanOption({
    required this.code,
    required this.priceNpr,
    required this.billing,
    required this.staffSeats,
    required this.totalMembers,
    required this.contactSales,
  });

  factory PlanOption.fromJson(Map<String, dynamic> json) {
    return PlanOption(
      code: (json['code'] as String?) ?? '',
      priceNpr: (json['priceNpr'] as num?)?.toInt(),
      billing: json['billing'] as String?,
      staffSeats: (json['staffSeats'] as num?)?.toInt(),
      totalMembers: (json['totalMembers'] as num?)?.toInt(),
      contactSales: json['contactSales'] == true,
    );
  }
}

class PaymentInfo {
  final String? qrImageUrl;
  final String? paymentNote;

  const PaymentInfo({this.qrImageUrl, this.paymentNote});

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      qrImageUrl: json['qrImageUrl'] as String?,
      paymentNote: json['paymentNote'] as String?,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
