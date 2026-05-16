class UpdateProfileRequest {
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String? imageKey;
  final String? companyName;
  final String? companyEmail;
  final String? companyPhone;

  UpdateProfileRequest({
    this.fullName,
    this.phoneNumber,
    this.email,
    this.imageKey,
    this.companyName,
    this.companyEmail,
    this.companyPhone,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (fullName != null) {
      data['fullName'] = fullName;
    }
    if (phoneNumber != null) {
      data['phoneNumber'] = phoneNumber;
    }
    if (email != null) {
      data['email'] = email;
    }
    if (imageKey != null) {
      data['imageKey'] = imageKey;
    }
    if (companyName != null) {
      data['companyName'] = companyName;
    }
    if (companyEmail != null) {
      data['companyEmail'] = companyEmail;
    }
    if (companyPhone != null) {
      data['companyPhone'] = companyPhone;
    }
    
    return data;
  }
}
