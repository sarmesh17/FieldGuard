/// Approval state of the signed-in user's company.
///
/// Source of truth is `GET /api/v1/company`, which returns this for every role
/// (ADMIN/MANAGER/EMPLOYEE) and is reachable even while the company is pending.
/// We never trust the login/refresh response for this — the short-lived access
/// token has no approval claim, so approval must be re-fetched on every
/// app-open and after each login.
enum ApprovalStatus {
  approved,
  pendingApproval,
  rejected,

  /// Status string we did not recognise. Treated conservatively (gated) by the
  /// router so a backend rename can never accidentally unlock the app.
  unknown;

  static ApprovalStatus fromApi(String? raw) {
    switch (raw) {
      case 'APPROVED':
        return ApprovalStatus.approved;
      case 'PENDING_APPROVAL':
        return ApprovalStatus.pendingApproval;
      case 'REJECTED':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.unknown;
    }
  }
}

class CompanyApprovalResponse {
  final ApprovalStatus approvalStatus;
  final String? rejectionReason;

  const CompanyApprovalResponse({
    required this.approvalStatus,
    this.rejectionReason,
  });

  factory CompanyApprovalResponse.fromJson(Map<String, dynamic> json) {
    // Unwrap the common envelopes: { data: { company: {...} } },
    // { company: {...} }, or the bare company object itself.
    final body = json['data'] as Map<String, dynamic>? ?? json;
    final company = body['company'] as Map<String, dynamic>? ?? body;

    final rawStatus =
        (company['approvalStatus'] ?? company['approval_status']) as String?;
    final reason =
        (company['rejectionReason'] ?? company['rejection_reason']) as String?;

    return CompanyApprovalResponse(
      approvalStatus: ApprovalStatus.fromApi(rawStatus),
      rejectionReason: reason,
    );
  }
}
