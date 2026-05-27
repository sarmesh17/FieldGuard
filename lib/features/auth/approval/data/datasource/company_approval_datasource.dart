import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/approval/data/dto/company_approval_response.dart';

abstract class CompanyApprovalDataSource {
  /// Fetches the current company approval status from `GET /api/v1/company`.
  Future<Result<CompanyApprovalResponse>> getApprovalStatus();
}
