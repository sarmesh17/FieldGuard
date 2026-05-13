class AuthUser {
  final String id;
  final String name;
  final String phone;
  final String? role;

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.role,
  });
}
