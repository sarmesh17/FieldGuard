class ProfileResponse {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String role;
  final String employeeCode;
  final bool isActive;
  final String? profileImage;
  final String? lastLoginAt;
  final String createdAt;
  final CompanyInfo? company;

  ProfileResponse({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.role,
    required this.employeeCode,
    required this.isActive,
    this.profileImage,
    this.lastLoginAt,
    required this.createdAt,
    this.company,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return ProfileResponse(
      id: user['id'] as int,
      fullName: user['full_name'] as String,
      phoneNumber: user['phone_number'] as String,
      email: user['email'] as String?,
      role: user['role'] as String,
      employeeCode: user['employee_code'] as String,
      isActive: user['is_active'] as bool,
      profileImage: user['profile_image'] as String?,
      lastLoginAt: user['last_login_at'] as String?,
      createdAt: user['created_at'] as String,
      company: user['company'] != null
          ? CompanyInfo.fromJson(user['company'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'role': role,
        'employee_code': employeeCode,
        'is_active': isActive,
        'profile_image': profileImage,
        'last_login_at': lastLoginAt,
        'created_at': createdAt,
        'company': company?.toJson(),
      }
    };
  }
}

class CompanyInfo {
  final int id;
  final String companyName;
  final String? email;
  final String? phoneNumber;
  final String companyUniqueId;

  CompanyInfo({
    required this.id,
    required this.companyName,
    this.email,
    this.phoneNumber,
    required this.companyUniqueId,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['id'] as int,
      companyName: json['company_name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      companyUniqueId: json['company_unique_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'email': email,
      'phone_number': phoneNumber,
      'company_unique_id': companyUniqueId,
    };
  }
}
