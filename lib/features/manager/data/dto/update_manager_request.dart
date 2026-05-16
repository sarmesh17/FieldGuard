class UpdateManagerRequest {
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final bool? isActive;
  final String? imageKey;

  UpdateManagerRequest({
    this.fullName,
    this.phoneNumber,
    this.email,
    this.isActive,
    this.imageKey,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (fullName != null) data['fullName'] = fullName;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (email != null) data['email'] = email;
    if (isActive != null) data['isActive'] = isActive;
    if (imageKey != null) data['imageKey'] = imageKey;
    
    return data;
  }
}
