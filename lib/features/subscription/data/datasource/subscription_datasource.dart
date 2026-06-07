import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/subscription/data/dto/enterprise_inquiry.dart';
import 'package:fieldguard/features/subscription/data/dto/invoice.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_request_item.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_response.dart';

abstract class SubscriptionDataSource {
  /// Current plan + seat usage + plan catalogue + payment QR.
  Future<Result<SubscriptionResponse>> getSubscription();

  /// This company's subscription invoices (newest first), auto-generated on
  /// payment approval. Read-only.
  Future<Result<List<Invoice>>> getInvoices();

  /// Submit a paid-plan (STARTER / GROWTH) upgrade request. A
  /// [ConflictException] failure means a request is already pending (only one
  /// allowed at a time).
  Future<Result<SubscriptionRequestItem>> submitRequest({
    required String plan,
    required int months,
    required String paymentProofImageKey,
  });

  /// Upgrade requests, newest first — polled while one is pending.
  Future<Result<List<SubscriptionRequestItem>>> getRequests();

  /// Submit an ENTERPRISE "Talk to us" call request. A [ConflictException]
  /// failure means one is already PENDING (only one allowed at a time).
  Future<Result<EnterpriseInquiry>> submitEnterpriseInquiry({
    required String contactPhone,
    int? expectedStaffCount,
    String? message,
  });

  /// This company's enterprise inquiries, newest first — to track status.
  Future<Result<List<EnterpriseInquiry>>> getEnterpriseInquiries();
}
