/// Core user entity — contains only business-relevant fields.
/// No JSON serialization here; that belongs in the data layer.
class User {
  final String id;
  final String email;
  final String role; // e.g. 'manager' | 'admin'
  final String? name;

  const User({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });
}
