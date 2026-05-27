/// Response for `POST /api/v1/collections`. The outstanding snapshot is the
/// post-write authoritative state — same shape as `GET /collections/shops/
/// {shopId}/outstanding`. The smsPreview is byte-identical to what the shop
/// owner receives; render it verbatim.
class CreateCollectionResponse {
  final CollectionRecord collection;
  final OutstandingSnapshot outstanding;

  /// Zero or one entry. Empty when method=CHEQUE (still PENDING, SMS waits
  /// for settlement) or the shop has no valid contact phone.
  final List<SmsPreview> smsPreview;

  const CreateCollectionResponse({
    required this.collection,
    required this.outstanding,
    required this.smsPreview,
  });

  factory CreateCollectionResponse.fromJson(Map<String, dynamic> json) {
    return CreateCollectionResponse(
      collection: CollectionRecord.fromJson(
        json['collection'] as Map<String, dynamic>,
      ),
      outstanding: OutstandingSnapshot.fromJson(
        json['outstanding'] as Map<String, dynamic>,
      ),
      smsPreview: (json['smsPreview'] as List<dynamic>? ?? const [])
          .map((e) => SmsPreview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CollectionRecord {
  final int id;
  final int shopId;
  final int collectedBy;
  final String amount; // Decimal as string
  final String method; // CASH | CHEQUE
  final String status; // CLEARED | PENDING
  final String? chequeNumber;
  final String? chequeBank;
  final String? chequeDate;
  final String? notes;
  final int? settledBy;
  final String? clearedAt;
  final String createdAt;
  final CollectionPerson collector;

  /// Populated only after an admin settles the collection (otherwise null).
  final CollectionPerson? settler;
  final CollectionShop shop;

  const CollectionRecord({
    required this.id,
    required this.shopId,
    required this.collectedBy,
    required this.amount,
    required this.method,
    required this.status,
    this.chequeNumber,
    this.chequeBank,
    this.chequeDate,
    this.notes,
    this.settledBy,
    this.clearedAt,
    required this.createdAt,
    required this.collector,
    this.settler,
    required this.shop,
  });

  factory CollectionRecord.fromJson(Map<String, dynamic> json) {
    return CollectionRecord(
      id: (json['id'] as num).toInt(),
      shopId: (json['shop_id'] as num).toInt(),
      collectedBy: (json['collected_by'] as num).toInt(),
      amount: json['amount']?.toString() ?? '0',
      method: json['method'] as String? ?? 'CASH',
      status: json['status'] as String? ?? 'CLEARED',
      chequeNumber: json['cheque_number'] as String?,
      chequeBank: json['cheque_bank'] as String?,
      chequeDate: json['cheque_date'] as String?,
      notes: json['notes'] as String?,
      settledBy: (json['settled_by'] as num?)?.toInt(),
      clearedAt: json['cleared_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      collector:
          CollectionPerson.fromJson(json['collector'] as Map<String, dynamic>),
      settler: json['settler'] != null
          ? CollectionPerson.fromJson(json['settler'] as Map<String, dynamic>)
          : null,
      shop: CollectionShop.fromJson(json['shop'] as Map<String, dynamic>),
    );
  }
}

class CollectionPerson {
  final int id;
  final String fullName;
  final String? role;
  final String? employeeCode;

  const CollectionPerson({
    required this.id,
    required this.fullName,
    this.role,
    this.employeeCode,
  });

  factory CollectionPerson.fromJson(Map<String, dynamic> json) {
    return CollectionPerson(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String?,
      employeeCode: json['employee_code'] as String?,
    );
  }
}

class CollectionShop {
  final int id;
  final String name;

  const CollectionShop({required this.id, required this.name});

  factory CollectionShop.fromJson(Map<String, dynamic> json) {
    return CollectionShop(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
    );
  }
}

/// Post-write outstanding state for the shop. All amounts are Decimal strings
/// (Prisma serialisation) — parse with [double.tryParse] before arithmetic.
class OutstandingSnapshot {
  final int shopId;
  final String shopName;
  final String totalDue;
  final String collected;
  final String pendingCheques;
  final String outstanding;

  const OutstandingSnapshot({
    required this.shopId,
    required this.shopName,
    required this.totalDue,
    required this.collected,
    required this.pendingCheques,
    required this.outstanding,
  });

  factory OutstandingSnapshot.fromJson(Map<String, dynamic> json) {
    return OutstandingSnapshot(
      shopId: (json['shop_id'] as num).toInt(),
      shopName: json['shop_name'] as String? ?? '',
      totalDue: json['total_due']?.toString() ?? '0',
      collected: json['collected']?.toString() ?? '0',
      pendingCheques: json['pending_cheques']?.toString() ?? '0',
      outstanding: json['outstanding']?.toString() ?? '0',
    );
  }
}

class SmsPreview {
  final String kind;
  final String recipient;
  final String body;

  const SmsPreview({
    required this.kind,
    required this.recipient,
    required this.body,
  });

  factory SmsPreview.fromJson(Map<String, dynamic> json) {
    return SmsPreview(
      kind: json['kind'] as String? ?? '',
      recipient: json['recipient'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}
