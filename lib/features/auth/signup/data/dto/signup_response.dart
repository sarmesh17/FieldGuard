class SignupResponse {
  final String message;

  const SignupResponse({required this.message});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    final body = json['data'] as Map<String, dynamic>? ?? json;
    return SignupResponse(
      message: (body['message'] ?? 'Registration successful') as String,
    );
  }
}
