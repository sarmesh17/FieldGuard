class CreateManagerRequest {
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String password;
  final String? profileImage; // Base64 encoded image

  CreateManagerRequest({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.password,
    this.profileImage,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': password,
    };

    if (email != null && email!.isNotEmpty) {
      data['email'] = email;
    }

    if (profileImage != null && profileImage!.isNotEmpty) {
      data['profileImage'] = profileImage;
    }

    return data;
  }
}
