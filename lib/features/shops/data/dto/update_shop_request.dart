class UpdateShopRequest {
  final String name;
  final String? panNumber;
  final String address;
  final double latitude;
  final double longitude;
  final String contactName;
  final String contactPhone;
  final bool isActive;
  final String? imageKey;

  const UpdateShopRequest({
    required this.name,
    this.panNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
    required this.isActive,
    this.imageKey,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'isActive': isActive,
    };
    if (panNumber != null && panNumber!.isNotEmpty) {
      map['panNumber'] = panNumber;
    }
    if (imageKey != null) {
      map['imageKey'] = imageKey;
    }
    return map;
  }
}
