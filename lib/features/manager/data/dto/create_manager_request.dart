class CreateManagerRequest {
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String password;
  final String? imageKey; // S3 image key from upload service

  CreateManagerRequest({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.password,
    this.imageKey,
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

    if (imageKey != null && imageKey!.isNotEmpty) {
      data['imageKey'] = imageKey;
    }

    return data;
  }
}
