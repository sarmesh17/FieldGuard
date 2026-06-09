import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/subscription/data/datasource/subscription_datasource.dart';
import 'package:fieldguard/features/subscription/data/datasource/subscription_datasource_impl.dart';
import 'package:fieldguard/features/subscription/data/dto/invoice.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _subscriptionDioProvider = Provider<Dio>((ref) => DioClient.createDio());

final subscriptionDataSourceProvider = Provider<SubscriptionDataSource>(
  (ref) => SubscriptionDataSourceImpl(ref.watch(_subscriptionDioProvider)),
);

/// Current plan + seat usage + plan catalogue + payment QR.
///
/// `ref.invalidate(subscriptionProvider)` re-fetches it — used after an upgrade
/// is approved so the screen reflects the new PRO plan and seats.
final subscriptionProvider =
    FutureProvider.autoDispose<SubscriptionResponse>((ref) async {
  final result = await ref.watch(subscriptionDataSourceProvider).getSubscription();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final exception) => throw exception,
  };
});

/// This company's subscription invoices (newest first). Auto-disposed; pull
/// to refresh re-fetches via `ref.invalidate(invoicesProvider)`.
final invoicesProvider = FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final result = await ref.watch(subscriptionDataSourceProvider).getInvoices();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final exception) => throw exception,
  };
});
