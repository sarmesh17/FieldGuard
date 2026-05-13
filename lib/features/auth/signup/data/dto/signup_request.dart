class SignupRequest {
  final String companyName;
  final String panNumber;
  final String adminName;
  final String phoneNumber;
  final String password;
  final String citizenshipImagePath;
  final String registrationDocPath;

  const SignupRequest({
    required this.companyName,
    required this.panNumber,
    required this.adminName,
    required this.phoneNumber,
    required this.password,
    required this.citizenshipImagePath,
    required this.registrationDocPath,
  });
}
