class ManagersListResponse {
  final List<ManagerItem> managers;

  ManagersListResponse({required this.managers});

  factory ManagersListResponse.fromJson(Map<String, dynamic> json) {
    final managersList = json['managers'] as List<dynamic>? ?? [];
    return ManagersListResponse(
      managers: managersList
          .map((e) => ManagerItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ManagerItem {
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
  final int assignedCount;
  final int createdCount;

  ManagerItem({
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
    required this.assignedCount,
    required this.createdCount,
  });

  factory ManagerItem.fromJson(Map<String, dynamic> json) {
    return ManagerItem(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      role: json['role'] ?? '',
      managerCode: json['manager_code'] ?? '',
      isActive: json['is_active'] ?? false,
      profileImage: json['profile_image'],
      createdAt: json['created_at'] ?? '',
      assignedCount: json['assignedCount'] ?? 0,
      createdCount: json['createdCount'] ?? 0,
    );
  }
}
