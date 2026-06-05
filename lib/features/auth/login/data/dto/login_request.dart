class LoginRequest {
  final String phoneNumber;
  final String password;
  final bool termsAccepted;
  final String termsVersion;

  const LoginRequest({
    required this.phoneNumber,
    required this.password,
    required this.termsAccepted,
    required this.termsVersion,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'password': password,
        // Consent must be sent as a pair, with termsAccepted == true, or the
        // backend returns 400. The UI gates submission so this is always true.
        'termsAccepted': termsAccepted,
        'termsVersion': termsVersion,
      };
}
