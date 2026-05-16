class EmployeesListResponse {
  final List<EmployeeItem> employees;

  EmployeesListResponse({required this.employees});

  factory EmployeesListResponse.fromJson(Map<String, dynamic> json) {
    final employeesList = json['employees'] as List<dynamic>? ?? [];
    return EmployeesListResponse(
      employees: employeesList
          .map((e) => EmployeeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EmployeeItem {
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

  EmployeeItem({
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

  factory EmployeeItem.fromJson(Map<String, dynamic> json) {
    return EmployeeItem(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      role: json['role'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      managerId: json['manager_id']?.toString(),
      isActive: json['is_active'] ?? false,
      profileImage: json['profile_image'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
