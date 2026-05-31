class SignupRequest {
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String panNumber;
  final String adminName;
  final String phoneNumber;
  final String password;
  final bool termsAccepted;
  final String termsVersion;

  const SignupRequest({
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    required this.panNumber,
    required this.adminName,
    required this.phoneNumber,
    required this.password,
    required this.termsAccepted,
    required this.termsVersion,
  });

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'companyEmail': companyEmail,
    'companyPhone': companyPhone,
    'panNumber': panNumber,
    'adminName': adminName,
    'phoneNumber': phoneNumber,
    'password': password,
    // Consent must be sent as a pair, with termsAccepted == true, or the
    // backend returns 400. The UI gates submission so this is always true.
    'termsAccepted': termsAccepted,
    'termsVersion': termsVersion,
  };
}
