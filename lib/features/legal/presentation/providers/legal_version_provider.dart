import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/legal/data/legal_content_response.dart';
import 'package:fieldguard/features/legal/data/legal_datasource.dart';
import 'package:fieldguard/features/legal/legal_content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final legalDatasourceProvider = Provider<LegalDatasource>(
  (ref) => LegalDatasource(DioClient.createDio()),
);

/// The full Terms & Privacy content for the legal screen. Unlike the version
/// provider, this does NOT fall back to bundled text — on failure it surfaces
/// the error so the screen can show a retry (we must never show stale text
/// while recording consent against the current version).
final legalContentProvider = FutureProvider<LegalContentResponse>((ref) async {
  final result = await ref.watch(legalDatasourceProvider).fetchContent();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final exception) => throw exception,
  };
});

/// The current legal version, fetched from the backend (the source of truth).
///
/// Watch this when a consent screen loads so the version is ready by submit
/// time. If the request fails we fall back to the bundled [kLegalLastUpdated]
/// so the consent payload always carries a version and login/registration are
/// never blocked by a hiccup on the version endpoint.
final legalVersionProvider = FutureProvider<String>((ref) async {
  final result = await ref.watch(legalDatasourceProvider).fetchVersion();
  return switch (result) {
    Success(:final data) => data,
    Failure() => kLegalLastUpdated,
  };
});
