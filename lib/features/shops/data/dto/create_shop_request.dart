class CreateShopRequest {
  final String name;
  final String? panNumber;
  final String address;
  final double latitude;
  final double longitude;
  final String contactName;
  final String contactPhone;
  final String? imageKey;

  const CreateShopRequest({
    required this.name,
    this.panNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
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
