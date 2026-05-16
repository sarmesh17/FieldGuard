class ShopsHierarchyResponse {
  final List<ManagerWithShops> managers;
  final List<EmployeeWithShops> directEmployees;
  final List<Shop> unassignedShops;

  ShopsHierarchyResponse({
    required this.managers,
    required this.directEmployees,
    required this.unassignedShops,
  });

  factory ShopsHierarchyResponse.fromJson(Map<String, dynamic> json) {
    return ShopsHierarchyResponse(
      managers: (json['managers'] as List<dynamic>?)
              ?.map((e) => ManagerWithShops.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      directEmployees: (json['directEmployees'] as List<dynamic>?)
              ?.map((e) => EmployeeWithShops.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unassignedShops: (json['unassignedShops'] as List<dynamic>?)
              ?.map((e) => Shop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ManagerWithShops {
  final ManagerInfo manager;
  final List<Shop> shops;
  final List<EmployeeWithShops> employees;

  ManagerWithShops({
    required this.manager,
    required this.shops,
    required this.employees,
  });

  factory ManagerWithShops.fromJson(Map<String, dynamic> json) {
    return ManagerWithShops(
      manager: ManagerInfo.fromJson(json['manager'] as Map<String, dynamic>),
      shops: (json['shops'] as List<dynamic>?)
              ?.map((e) => Shop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      employees: (json['employees'] as List<dynamic>?)
              ?.map((e) => EmployeeWithShops.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EmployeeWithShops {
  final EmployeeInfo employee;
  final List<Shop> shops;

  EmployeeWithShops({
    required this.employee,
    required this.shops,
  });

  factory EmployeeWithShops.fromJson(Map<String, dynamic> json) {
    return EmployeeWithShops(
      employee: EmployeeInfo.fromJson(json['employee'] as Map<String, dynamic>),
      shops: (json['shops'] as List<dynamic>?)
              ?.map((e) => Shop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ManagerInfo {
  final int id;
  final String fullName;
  final String employeeCode;
  final String? profileImage;

  ManagerInfo({
    required this.id,
    required this.fullName,
    required this.employeeCode,
    this.profileImage,
  });

  factory ManagerInfo.fromJson(Map<String, dynamic> json) {
    return ManagerInfo(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      employeeCode: json['employee_code'] as String,
      profileImage: json['profile_image'] as String?,
    );
  }
}

class EmployeeInfo {
  final int id;
  final String fullName;
  final String employeeCode;
  final String? profileImage;

  EmployeeInfo({
    required this.id,
    required this.fullName,
    required this.employeeCode,
    this.profileImage,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      employeeCode: json['employee_code'] as String,
      profileImage: json['profile_image'] as String?,
    );
  }
}

class Shop {
  final int id;
  final String name;
  final String address;
  final String latitude;
  final String longitude;
  final String contactName;
  final String contactPhone;
  final bool isActive;
  final String createdAt;
  final String? shopImage;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
    required this.isActive,
    required this.createdAt,
    this.shopImage,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      contactName: json['contact_name'] as String,
      contactPhone: json['contact_phone'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String,
      shopImage: json['shop_image'] as String?,
    );
  }
}
