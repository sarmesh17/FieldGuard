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

  /// Monthly SMS meter. Null on older payloads that don't send it yet.
  final SmsUsage? smsUsage;

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
    this.smsUsage,
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
      smsUsage: json['smsUsage'] is Map
          ? SmsUsage.fromJson((json['smsUsage'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  bool get isUnlimitedStaff => staffSeatLimit == null;
}

/// Monthly SMS meter from `subscription.smsUsage`. Enforced on every plan
/// (FREE 50, PRO 300, ENTERPRISE unlimited) — `overQuota` means SMS is BLOCKED.
class SmsUsage {
  final String month; // "2026-06"
  final int used;

  /// null = unlimited (ENTERPRISE).
  final int? quota;

  /// null = unlimited.
  final int? remaining;
  final bool unlimited;
  final bool overQuota;

  const SmsUsage({
    required this.month,
    required this.used,
    required this.quota,
    required this.remaining,
    required this.unlimited,
    required this.overQuota,
  });

  factory SmsUsage.fromJson(Map<String, dynamic> json) {
    return SmsUsage(
      month: (json['month'] as String?) ?? '',
      used: (json['used'] as num?)?.toInt() ?? 0,
      quota: (json['quota'] as num?)?.toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
      unlimited: json['unlimited'] == true,
      overQuota: json['overQuota'] == true,
    );
  }

  /// 0..1 fraction of quota used (1.0 when over / unknown quota). Unlimited → 0.
  double get fraction {
    if (unlimited) return 0;
    final q = quota ?? 0;
    if (q <= 0) return overQuota ? 1 : 0;
    return (used / q).clamp(0, 1).toDouble();
  }

  /// Near the cap (≤10% left) but not yet blocked — nudge an early upgrade.
  bool get nearLimit {
    if (unlimited || overQuota) return false;
    final q = quota ?? 0;
    if (q <= 0) return false;
    final rem = remaining ?? (q - used);
    return rem > 0 && rem <= (q * 0.1).ceil();
  }
}

class PlanOption {
  final String code; // FREE / STARTER / GROWTH / ENTERPRISE

  /// Display name from the API ("Free Trial", "Starter", …). Falls back to the
  /// code if the backend omits it.
  final String label;

  /// null for ENTERPRISE (custom pricing).
  final int? priceNpr;
  final String? billing; // null / "monthly" / "custom"

  /// null = unlimited.
  final int? staffSeats;

  /// null = unlimited.
  final int? totalMembers;

  /// When true, show "Talk to us" instead of a pay/upgrade button.
  final bool contactSales;

  /// Monthly SMS quota for this plan. null = unlimited (ENTERPRISE).
  final int? smsQuota;

  const PlanOption({
    required this.code,
    required this.label,
    required this.priceNpr,
    required this.billing,
    required this.staffSeats,
    required this.totalMembers,
    required this.contactSales,
    required this.smsQuota,
  });

  factory PlanOption.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] as String?) ?? '';
    return PlanOption(
      code: code,
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? (json['label'] as String)
          : code,
      priceNpr: (json['priceNpr'] as num?)?.toInt(),
      billing: json['billing'] as String?,
      staffSeats: (json['staffSeats'] as num?)?.toInt(),
      totalMembers: (json['totalMembers'] as num?)?.toInt(),
      contactSales: json['contactSales'] == true,
      smsQuota: (json['smsQuota'] as num?)?.toInt(),
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
