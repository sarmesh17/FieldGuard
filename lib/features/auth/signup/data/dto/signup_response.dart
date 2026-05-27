class SignupResponse {
  final String accessToken;
  final String refreshToken;
  final RegisteredCompany company;

  const SignupResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.company,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    final body = json['data'] as Map<String, dynamic>? ?? json;
    return SignupResponse(
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
      company: RegisteredCompany.fromJson(
        body['company'] as Map<String, dynamic>,
      ),
    );
  }
}

class RegisteredCompany {
  final int id;
  final String uniqueId;
  final String name;
  final String? citizenshipImage;
  final String? registrationDocument;

  const RegisteredCompany({
    required this.id,
    required this.uniqueId,
    required this.name,
    this.citizenshipImage,
    this.registrationDocument,
  });

  factory RegisteredCompany.fromJson(Map<String, dynamic> json) {
    return RegisteredCompany(
      id: (json['id'] as num).toInt(),
      uniqueId: (json['uniqueId'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      citizenshipImage: json['citizenshipImage'] as String?,
      registrationDocument: json['registrationDocument'] as String?,
    );
  }
}
