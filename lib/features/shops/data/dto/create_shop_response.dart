class CreateShopResponse {
  final ShopData? shop;

  const CreateShopResponse({this.shop});

  factory CreateShopResponse.fromJson(Map<String, dynamic> json) {
    return CreateShopResponse(
      shop: json['shop'] != null
          ? ShopData.fromJson(json['shop'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ShopData {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String contactName;
  final String contactPhone;
  final bool isActive;
  final String createdAt;
  final String? shopImage;

  const ShopData({
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

  factory ShopData.fromJson(Map<String, dynamic> json) {
    return ShopData(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      contactName: json['contact_name'] ?? json['contactName'] ?? '',
      contactPhone: json['contact_phone'] ?? json['contactPhone'] ?? '',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      shopImage: json['shop_image'] ?? json['shopImage'] as String?,
    );
  }
}
