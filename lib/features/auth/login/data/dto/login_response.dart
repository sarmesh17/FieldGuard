class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final LoginUser user;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: LoginUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class LoginUser {
  final int id;
  final String name;
  final String role;
  final int companyId;
  final String employeeCode;

  const LoginUser({
    required this.id,
    required this.name,
    required this.role,
    required this.companyId,
    required this.employeeCode,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String,
      companyId: json['companyId'] as int,
      employeeCode: json['employeeCode'] as String,
    );
  }
}
