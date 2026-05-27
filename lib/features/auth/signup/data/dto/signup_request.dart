class SignupRequest {
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String panNumber;
  final String adminName;
  final String phoneNumber;
  final String password;

  const SignupRequest({
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    required this.panNumber,
    required this.adminName,
    required this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'companyEmail': companyEmail,
    'companyPhone': companyPhone,
    'panNumber': panNumber,
    'adminName': adminName,
    'phoneNumber': phoneNumber,
    'password': password,
  };
}
