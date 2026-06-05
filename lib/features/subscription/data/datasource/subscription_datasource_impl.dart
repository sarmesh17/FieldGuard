import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/network_exception_mapper.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/subscription/data/datasource/subscription_datasource.dart';
import 'package:fieldguard/features/subscription/data/dto/enterprise_inquiry.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_request_item.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_response.dart';

class SubscriptionDataSourceImpl extends SubscriptionDataSource with ApiRunner {
  final Dio _dio;

  SubscriptionDataSourceImpl(this._dio);

  @override
  Future<Result<SubscriptionResponse>> getSubscription() => safeCall(() async {
        final response = await _dio.get(
          ApiConstant.companySubscriptionEndpoint,
        );
        return SubscriptionResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      });

  @override
  Future<Result<SubscriptionRequestItem>> submitRequest({
    required int months,
    required String paymentProofImageKey,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstant.subscriptionRequestEndpoint,
        data: {
          'months': months,
          'paymentProofImageKey': paymentProofImageKey,
        },
      );
      final body = response.data as Map<String, dynamic>;
      // 201 wraps the new request in `{ request: {...} }`.
      final requestJson = (body['request'] as Map?)?.cast<String, dynamic>() ??
          body;
      return Success(SubscriptionRequestItem.fromJson(requestJson));
    } on DioException catch (e) {
      // 409 = a request is already pending (one at a time). Surface it as a
      // conflict so the UI can route straight to the waiting screen instead of
      // showing it as a hard error.
      if (e.response?.statusCode == 409) {
        final message = _bodyMessage(e.response?.data) ??
            'You already have a pending upgrade request.';
        return Failure(ConflictException(message));
      }
      return Failure(NetworkExceptionMapper.map(e));
    } on AppException catch (e) {
      return Failure(e);
    } catch (_) {
      return Failure(const ServerException(AppStrings.serverError));
    }
  }

  @override
  Future<Result<List<SubscriptionRequestItem>>> getRequests() =>
      safeCall(() async {
        final response = await _dio.get(
          ApiConstant.subscriptionRequestsEndpoint,
        );
        return _parseRequests(response.data);
      });

  @override
  Future<Result<EnterpriseInquiry>> submitEnterpriseInquiry({
    required String contactPhone,
    int? expectedStaffCount,
    String? message,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstant.enterpriseInquiryEndpoint,
        data: {
          'contactPhone': contactPhone,
          'expectedStaffCount': ?expectedStaffCount,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );
      final body = response.data as Map<String, dynamic>;
      // 201 wraps the new inquiry in `{ inquiry: {...} }`.
      final inquiryJson =
          (body['inquiry'] as Map?)?.cast<String, dynamic>() ?? body;
      return Success(EnterpriseInquiry.fromJson(inquiryJson));
    } on DioException catch (e) {
      // 409 = a request is already pending (one at a time). Surface it as a
      // conflict so the UI shows the "we'll call you" state instead of a hard
      // error.
      if (e.response?.statusCode == 409) {
        final message = _bodyMessage(e.response?.data) ??
            'You already have a pending request — our team will call you.';
        return Failure(ConflictException(message));
      }
      return Failure(NetworkExceptionMapper.map(e));
    } on AppException catch (e) {
      return Failure(e);
    } catch (_) {
      return Failure(const ServerException(AppStrings.serverError));
    }
  }

  @override
  Future<Result<List<EnterpriseInquiry>>> getEnterpriseInquiries() =>
      safeCall(() async {
        final response = await _dio.get(
          ApiConstant.enterpriseInquiriesEndpoint,
        );
        return _parseInquiries(response.data);
      });

  /// The list endpoint may answer as a bare array or wrap it under `requests` /
  /// `data`; accept either so a backend tweak doesn't break polling.
  static List<SubscriptionRequestItem> _parseRequests(Object? data) {
    List? list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final inner = data['requests'] ?? data['data'];
      if (inner is List) list = inner;
    }
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((e) => SubscriptionRequestItem.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Accepts a bare array or a `{ inquiries: [...] }` / `{ data: [...] }`
  /// wrapper, so a backend shape tweak doesn't break the list.
  static List<EnterpriseInquiry> _parseInquiries(Object? data) {
    List? list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final inner = data['inquiries'] ?? data['data'];
      if (inner is List) list = inner;
    }
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((e) => EnterpriseInquiry.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  static String? _bodyMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }
}
