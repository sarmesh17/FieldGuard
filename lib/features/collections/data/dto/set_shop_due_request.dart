/// Body for `PUT /api/v1/collections/shops/{shopId}/due`.
///
/// Sets or adjusts the shop's total due amount. Only ADMIN or MANAGER roles
/// can invoke this. The [totalDue] value replaces the current total_due for the
/// shop's money snapshot.
class SetShopDueRequest {
  final double totalDue;

  const SetShopDueRequest({required this.totalDue});

  Map<String, dynamic> toJson() => {'totalDue': totalDue};
}
