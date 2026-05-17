import '../../domain/entities/user.dart';

/// Data-layer representation of [User] with JSON serialization.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.name,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        name: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        if (name != null) 'name': name,
      };
}
