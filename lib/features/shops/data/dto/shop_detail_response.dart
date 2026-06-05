class ShopDetailResponse {
  final ShopDetailData shop;

  const ShopDetailResponse({required this.shop});

  factory ShopDetailResponse.fromJson(Map<String, dynamic> json) {
    return ShopDetailResponse(
      shop: ShopDetailData.fromJson(json['shop'] as Map<String, dynamic>),
    );
  }
}

class ShopDetailData {
  final int id;
  final String name;
  final String address;
  final String? panNumber;
  final String latitude;
  final String longitude;
  final String contactName;
  final String contactPhone;
  final String? shopImage;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final Creator creator;

  const ShopDetailData({
    required this.id,
    required this.name,
    required this.address,
    this.panNumber,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
    this.shopImage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.creator,
  });

  factory ShopDetailData.fromJson(Map<String, dynamic> json) {
    return ShopDetailData(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      panNumber: json['pan_number'] as String?,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      contactName: json['contact_name'] as String,
      contactPhone: json['contact_phone'] as String,
      shopImage: json['shop_image'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
    );
  }
}

class Creator {
  final int id;
  final String fullName;
  final String employeeCode;
  final String? profileImage;

  const Creator({
    required this.id,
    required this.fullName,
    required this.employeeCode,
    this.profileImage,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      employeeCode: json['employee_code'] as String,
      profileImage: json['profile_image'] as String?,
    );
  }
}
