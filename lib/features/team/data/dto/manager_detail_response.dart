class ManagerDetailResponse {
  final ManagerDetail manager;

  ManagerDetailResponse({required this.manager});

  factory ManagerDetailResponse.fromJson(Map<String, dynamic> json) {
    return ManagerDetailResponse(
      manager: ManagerDetail.fromJson(json['manager'] as Map<String, dynamic>),
    );
  }
}

class ManagerDetail {
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
  final String updatedAt;
  final int createdCount;
  final int assignedCount;
  final List<dynamic> assignedEmployees;
  final List<dynamic> createdEmployees;

  ManagerDetail({
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
    required this.updatedAt,
    required this.createdCount,
    required this.assignedCount,
    required this.assignedEmployees,
    required this.createdEmployees,
  });

  factory ManagerDetail.fromJson(Map<String, dynamic> json) {
    return ManagerDetail(
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
      updatedAt: json['updated_at'] as String? ?? '',
      createdCount: json['createdCount'] as int? ?? 0,
      assignedCount: json['assignedCount'] as int? ?? 0,
      assignedEmployees: json['assignedEmployees'] as List<dynamic>? ?? [],
      createdEmployees: json['createdEmployees'] as List<dynamic>? ?? [],
    );
  }
}
