/// Payment method. Server decides the persisted status from this:
/// CASH → CLEARED (SMS fires immediately); CHEQUE → PENDING (SMS waits for
/// settlement); ONLINE → CLEARED immediately (digital payment already received).
enum CollectionMethod {
  cash('CASH'),
  cheque('CHEQUE'),
  online('ONLINE');

  const CollectionMethod(this.wire);
  final String wire;
}

/// Body for `POST /api/v1/collections`.
///
/// Auth: CASH/CHEQUE → EMPLOYEE or MANAGER; ONLINE → ADMIN or MANAGER only
/// (EMPLOYEE → 403). ADMIN cannot record CASH/CHEQUE.
///
/// Field rules:
/// - [CollectionMethod.cheque]: [chequeNumber] is required, [chequeBank] and
///   [chequeDate] are encouraged but optional.
/// - [CollectionMethod.online]: [onlineProvider] is required (ESEWA/KHALTI/BANK
///   or free text), [onlineRef] is optional (txn reference).
/// Fields not relevant to the chosen method are omitted from the wire.
class CreateCollectionRequest {
  final int shopId;

  /// Task this collection belongs to (optional). When sent, the task's
  /// responsible manager also gets the SMS. Omitting it keeps the old
  /// behaviour (admin + org manager only). Must be a task of [shopId].
  final int? taskId;
  final double amount;
  final CollectionMethod method;
  final String? chequeNumber;
  final String? chequeBank;
  final String? chequeDate; // ISO YYYY-MM-DD
  /// ONLINE only — payment rail (ESEWA | KHALTI | BANK | free text, max 40).
  final String? onlineProvider;
  /// ONLINE only — optional transaction reference (max 100).
  final String? onlineRef;
  final String? notes;

  const CreateCollectionRequest({
    required this.shopId,
    this.taskId,
    required this.amount,
    required this.method,
    this.chequeNumber,
    this.chequeBank,
    this.chequeDate,
    this.onlineProvider,
    this.onlineRef,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'shopId': shopId,
      'amount': amount,
      'method': method.wire,
    };
    // Send as a number only when present — backward compatible.
    if (taskId != null) body['taskId'] = taskId;
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
    if (method == CollectionMethod.online) {
      // onlineProvider is required by the validator for ONLINE; the form gates
      // submission on it. onlineRef is optional (txn reference).
      if (onlineProvider != null && onlineProvider!.isNotEmpty) {
        body['onlineProvider'] = onlineProvider;
      }
      if (onlineRef != null && onlineRef!.isNotEmpty) {
        body['onlineRef'] = onlineRef;
      }
    }
    if (notes != null && notes!.isNotEmpty) body['notes'] = notes;
    return body;
  }
}
