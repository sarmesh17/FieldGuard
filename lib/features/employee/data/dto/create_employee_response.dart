class CreateEmployeeResponse {
  final EmployeeData? employee;

  CreateEmployeeResponse({
    this.employee,
  });

  factory CreateEmployeeResponse.fromJson(Map<String, dynamic> json) {
    return CreateEmployeeResponse(
      employee: json['employee'] != null 
          ? EmployeeData.fromJson(json['employee']) 
          : null,
    );
  }
}

class EmployeeData {
  final String id;
  final String companyId;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String employeeCode;
  final String? email;
  final bool isActive;
  final String? profileImage;
  final String? managerId;
  final String createdAt;

  EmployeeData({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.employeeCode,
    this.email,
    required this.isActive,
    this.profileImage,
    this.managerId,
    required this.createdAt,
  });

  factory EmployeeData.fromJson(Map<String, dynamic> json) {
    return EmployeeData(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      email: json['email'],
      isActive: json['is_active'] ?? false,
      profileImage: json['profile_image'],
      managerId: json['manager_id']?.toString(),
      createdAt: json['created_at'] ?? '',
    );
  }
}
