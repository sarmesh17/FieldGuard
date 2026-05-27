class CreateShopResponse {
  final ShopData? shop;

  const CreateShopResponse({this.shop});

  factory CreateShopResponse.fromJson(Map<String, dynamic> json) {
    // The API returns the shop fields at the root; older callers expected a
    // `shop` envelope. Accept both.
    final source = json['shop'] is Map<String, dynamic>
        ? json['shop'] as Map<String, dynamic>
        : json;
    return CreateShopResponse(shop: ShopData.fromJson(source));
  }
}

class ShopData {
  final String id;
  final String name;
  final String address;
  final String? panNumber;
  final double latitude;
  final double longitude;
  final String contactName;
  final String contactPhone;
  final bool isActive;
  final String createdAt;
  final String? shopImage;
  final List<ShopVisibleUser> visibleTo;

  const ShopData({
    required this.id,
    required this.name,
    required this.address,
    this.panNumber,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
    required this.isActive,
    required this.createdAt,
    this.shopImage,
    this.visibleTo = const [],
  });

  factory ShopData.fromJson(Map<String, dynamic> json) {
    final visible = json['visibleTo'] ?? json['visible_to'];
    return ShopData(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      panNumber: json['pan_number'] ?? json['panNumber'] as String?,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      contactName: json['contact_name'] ?? json['contactName'] ?? '',
      contactPhone: json['contact_phone'] ?? json['contactPhone'] ?? '',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      shopImage: json['shop_image'] ?? json['shopImage'] as String?,
      visibleTo: visible is List
          ? visible
              .whereType<Map<String, dynamic>>()
              .map(ShopVisibleUser.fromJson)
              .toList()
          : const [],
    );
  }
}

class ShopVisibleUser {
  final int id;
  final String fullName;
  final String role;
  final String code;
  final String? profileImage;

  const ShopVisibleUser({
    required this.id,
    required this.fullName,
    required this.role,
    required this.code,
    this.profileImage,
  });

  factory ShopVisibleUser.fromJson(Map<String, dynamic> json) {
    return ShopVisibleUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      role: json['role'] ?? '',
      // Managers expose `manager_code`, employees expose `employee_code`.
      code: json['employee_code'] ??
          json['manager_code'] ??
          json['code'] ??
          '',
      profileImage: json['profile_image'] ?? json['profileImage'] as String?,
    );
  }
}
