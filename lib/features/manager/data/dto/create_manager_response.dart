class CreateManagerResponse {
  final ManagerData? manager;

  CreateManagerResponse({
    this.manager,
  });

  factory CreateManagerResponse.fromJson(Map<String, dynamic> json) {
    return CreateManagerResponse(
      manager: json['manager'] != null 
          ? ManagerData.fromJson(json['manager']) 
          : null,
    );
  }
}

class ManagerData {
  final String id;
  final String companyId;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String managerCode;
  final String? email;
  final bool isActive;
  final String? profileImage;
  final String createdAt;

  ManagerData({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.managerCode,
    this.email,
    required this.isActive,
    this.profileImage,
    required this.createdAt,
  });

  factory ManagerData.fromJson(Map<String, dynamic> json) {
    return ManagerData(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? '',
      managerCode: json['manager_code'] ?? '',
      email: json['email'],
      isActive: json['is_active'] ?? false,
      profileImage: json['profile_image'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
