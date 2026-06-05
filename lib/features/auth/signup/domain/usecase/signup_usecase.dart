import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_request.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_response.dart';
import 'package:fieldguard/features/auth/signup/domain/models/registration_progress.dart';
import 'package:fieldguard/features/auth/signup/domain/repository/signup_repository.dart';

/// Drives the 4-step company registration flow:
/// register (JSON) → upload citizenship to S3 → upload legal doc to S3 →
/// confirm both keys on the company.
///
/// The flow is resumable: pass the [progress] from a previous failed
/// attempt and each already-completed step is skipped. This matters
/// because `POST /register` is not idempotent — a blind retry of the
/// whole flow would fail at step 1. [onProgress] fires after every
/// completed step so the caller can persist progress for the next retry;
/// [onStatus] reports the current step for the UI.
class SignupUsecase {
  final SignupRepository _repository;
  SignupUsecase(this._repository);

  Future<Result<SignupResponse>> call({
    required SignupRequest request,
    required String citizenshipImagePath,
    required String legalDocumentPath,
    RegistrationProgress progress = const RegistrationProgress(),
    void Function(String status)? onStatus,
    void Function(RegistrationProgress progress)? onProgress,
  }) async {
    var p = progress;

    // Step 1 — register. Skipped on a retry: the company already exists
    // from the first attempt and re-registering would fail.
    if (p.registered == null) {
      onStatus?.call('Registering company…');
      switch (await _repository.register(request)) {
        case Failure(:final exception):
          return Failure(exception);
        case Success(:final data):
          p = p.copyWith(registered: data);
          onProgress?.call(p);
      }
    }

    final registered = p.registered!;
    final token = registered.accessToken;
    final companyId = registered.company.id;

    // Step 2 — citizenship document.
    if (p.citizenshipKey == null) {
      onStatus?.call('Uploading citizenship document…');
      switch (await _repository.uploadDocument(
        filePath: citizenshipImagePath,
        companyId: companyId,
        accessToken: token,
      )) {
        case Failure(:final exception):
          return Failure(exception);
        case Success(:final data):
          p = p.copyWith(citizenshipKey: data);
          onProgress?.call(p);
      }
    }

    // Step 3 — legal/registration document.
    if (p.legalDocumentKey == null) {
      onStatus?.call('Uploading registration document…');
      switch (await _repository.uploadDocument(
        filePath: legalDocumentPath,
        companyId: companyId,
        accessToken: token,
      )) {
        case Failure(:final exception):
          return Failure(exception);
        case Success(:final data):
          p = p.copyWith(legalDocumentKey: data);
          onProgress?.call(p);
      }
    }

    // Step 4 — confirm. The backend confirm endpoint is idempotent, so a
    // retried confirm is safe; skipped only when already known-done.
    if (!p.confirmed) {
      onStatus?.call('Finalizing registration…');
      switch (await _repository.confirmDocuments(
        citizenshipImageKey: p.citizenshipKey!,
        legalDocumentImageKey: p.legalDocumentKey!,
        accessToken: token,
      )) {
        case Failure(:final exception):
          return Failure(exception);
        case Success():
          p = p.copyWith(confirmed: true);
          onProgress?.call(p);
      }
    }

    return Success(registered);
  }
}
