class UpdateManagerResponse {
  final ManagerData manager;

  UpdateManagerResponse({required this.manager});

  factory UpdateManagerResponse.fromJson(Map<String, dynamic> json) {
    return UpdateManagerResponse(
      manager: ManagerData.fromJson(json['manager'] as Map<String, dynamic>),
    );
  }
}

class ManagerData {
  final String id;
  final String companyId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String role;
  final String managerCode;
  final bool isActive;
  final String? profileImage;
  final String createdAt;

  ManagerData({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.role,
    required this.managerCode,
    required this.isActive,
    this.profileImage,
    required this.createdAt,
  });

  factory ManagerData.fromJson(Map<String, dynamic> json) {
    return ManagerData(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? '',
      managerCode: json['employee_code'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      profileImage: json['profile_image'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
