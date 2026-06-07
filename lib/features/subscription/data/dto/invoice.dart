/// A subscription invoice from `GET /api/v1/company/subscription/invoices`
/// (and embedded in the approve-plan response). Read-only — the backend
/// generates these automatically on payment approval. Everything needed to
/// render a printable receipt lives here.
class Invoice {
  final String invoiceNumber; // "INV-000001"
  final String status; // "PAID"
  final DateTime? issuedAt;
  final InvoiceParty seller;
  final InvoiceParty buyer;
  final InvoiceItem item;
  final int amountNpr; // integer NPR (999 = Rs 999)
  final String? paymentMethod; // "OFFLINE"

  const Invoice({
    required this.invoiceNumber,
    required this.status,
    required this.issuedAt,
    required this.seller,
    required this.buyer,
    required this.item,
    required this.amountNpr,
    required this.paymentMethod,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceNumber: (json['invoiceNumber'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      issuedAt: _date(json['issuedAt']),
      seller: InvoiceParty.fromJson(
        (json['seller'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      buyer: InvoiceParty.fromJson(
        (json['buyer'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      item: InvoiceItem.fromJson(
        (json['item'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      amountNpr: (json['amountNpr'] as num?)?.toInt() ?? 0,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }
}

/// Seller or buyer block. Fields are optional — seller PAN/address come from
/// backend config and may be null (fall back to frontend branding).
class InvoiceParty {
  final int? companyId;
  final String? name; // seller.name
  final String? companyName; // buyer.companyName
  final String? pan;
  final String? address;
  final String? contact;

  const InvoiceParty({
    this.companyId,
    this.name,
    this.companyName,
    this.pan,
    this.address,
    this.contact,
  });

  /// The display name regardless of which block this is.
  String get displayName => (name ?? companyName ?? '').trim();

  factory InvoiceParty.fromJson(Map<String, dynamic> json) {
    return InvoiceParty(
      companyId: (json['companyId'] as num?)?.toInt(),
      name: json['name'] as String?,
      companyName: json['companyName'] as String?,
      pan: json['pan'] as String?,
      address: json['address'] as String?,
      contact: json['contact'] as String?,
    );
  }
}

class InvoiceItem {
  final String description; // "Starter plan — 1 month"
  final String? plan; // "STARTER"
  final String? planLabel; // "Starter"
  final int months;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  const InvoiceItem({
    required this.description,
    required this.plan,
    required this.planLabel,
    required this.months,
    required this.periodStart,
    required this.periodEnd,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: (json['description'] as String?) ?? '',
      plan: json['plan'] as String?,
      planLabel: json['planLabel'] as String?,
      months: (json['months'] as num?)?.toInt() ?? 1,
      periodStart: _date(json['periodStart']),
      periodEnd: _date(json['periodEnd']),
    );
  }
}

/// Envelope: `{ count, invoices: [...] }`.
class InvoicesResponse {
  final int count;
  final List<Invoice> invoices;

  const InvoicesResponse({required this.count, required this.invoices});

  factory InvoicesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['invoices'];
    return InvoicesResponse(
      count: (json['count'] as num?)?.toInt() ?? 0,
      invoices: list is List
          ? list
              .whereType<Map>()
              .map((e) => Invoice.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }
}

DateTime? _date(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
