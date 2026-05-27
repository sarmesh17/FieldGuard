import 'package:fieldguard/features/auth/signup/data/dto/signup_response.dart';

/// Tracks how far the multi-step company registration has advanced.
///
/// `POST /company/register` is NOT idempotent — re-running it after the
/// company already exists fails. So when a step fails mid-flow (e.g. a
/// dropped response), the retry must resume from the failed step rather
/// than starting over. This holds the results of the steps already done.
class RegistrationProgress {
  /// Step 1 result — carries the company id and access token used by the
  /// remaining steps. Non-null once the company has been created.
  final SignupResponse? registered;

  /// Step 2 result — S3 key of the uploaded citizenship document.
  final String? citizenshipKey;

  /// Step 3 result — S3 key of the uploaded legal/registration document.
  final String? legalDocumentKey;

  /// Step 4 — true once both keys are confirmed on the company.
  final bool confirmed;

  const RegistrationProgress({
    this.registered,
    this.citizenshipKey,
    this.legalDocumentKey,
    this.confirmed = false,
  });

  /// True once the company has been created — a retry must skip step 1.
  bool get isStarted => registered != null;

  RegistrationProgress copyWith({
    SignupResponse? registered,
    String? citizenshipKey,
    String? legalDocumentKey,
    bool? confirmed,
  }) {
    return RegistrationProgress(
      registered: registered ?? this.registered,
      citizenshipKey: citizenshipKey ?? this.citizenshipKey,
      legalDocumentKey: legalDocumentKey ?? this.legalDocumentKey,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}
