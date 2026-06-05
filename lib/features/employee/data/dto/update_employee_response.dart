class UpdateEmployeeResponse {
  final EmployeeData employee;

  UpdateEmployeeResponse({required this.employee});

  factory UpdateEmployeeResponse.fromJson(Map<String, dynamic> json) {
    return UpdateEmployeeResponse(
      employee: EmployeeData.fromJson(json['employee'] as Map<String, dynamic>),
    );
  }
}

class EmployeeData {
  final String id;
  final String companyId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String role;
  final String employeeCode;
  final String? managerId;
  final bool isActive;
  final String? profileImage;
  final String createdAt;

  EmployeeData({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.role,
    required this.employeeCode,
    this.managerId,
    required this.isActive,
    this.profileImage,
    required this.createdAt,
  });

  factory EmployeeData.fromJson(Map<String, dynamic> json) {
    return EmployeeData(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? '',
      employeeCode: json['employee_code'] as String? ?? '',
      managerId: json['manager_id']?.toString(),
      isActive: json['is_active'] as bool? ?? false,
      profileImage: json['profile_image'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
