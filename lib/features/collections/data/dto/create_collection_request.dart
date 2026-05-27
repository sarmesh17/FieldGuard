/// Payment method. Server decides the persisted status from this:
/// CASH → CLEARED (SMS fires immediately); CHEQUE → PENDING (SMS waits for
/// settlement).
enum CollectionMethod {
  cash('CASH'),
  cheque('CHEQUE');

  const CollectionMethod(this.wire);
  final String wire;
}

/// Body for `POST /api/v1/collections`.
///
/// Auth: EMPLOYEE or MANAGER (ADMIN → 403).
///
/// Field rules ([CollectionMethod.cheque] only): [chequeNumber] is required,
/// [chequeBank] and [chequeDate] are encouraged but optional. For
/// [CollectionMethod.cash] all three cheque fields are omitted from the wire.
class CreateCollectionRequest {
  final int shopId;
  final double amount;
  final CollectionMethod method;
  final String? chequeNumber;
  final String? chequeBank;
  final String? chequeDate; // ISO YYYY-MM-DD
  final String? notes;

  const CreateCollectionRequest({
    required this.shopId,
    required this.amount,
    required this.method,
    this.chequeNumber,
    this.chequeBank,
    this.chequeDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'shopId': shopId,
      'amount': amount,
      'method': method.wire,
    };
    if (method == CollectionMethod.cheque) {
      // chequeNumber is required by the validator for CHEQUE; the form gates
      // submission on it, so we send whatever the caller passed verbatim.
      if (chequeNumber != null && chequeNumber!.isNotEmpty) {
        body['chequeNumber'] = chequeNumber;
      }
      if (chequeBank != null && chequeBank!.isNotEmpty) {
        body['chequeBank'] = chequeBank;
      }
      if (chequeDate != null && chequeDate!.isNotEmpty) {
        body['chequeDate'] = chequeDate;
      }
    }
    if (notes != null && notes!.isNotEmpty) body['notes'] = notes;
    return body;
  }
}
