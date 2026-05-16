class CreateEmployeeRequest {
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String password;
  final String? managerId;
  final String? imageKey; // S3 image key from upload service

  CreateEmployeeRequest({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.password,
    this.managerId,
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

    if (managerId != null && managerId!.isNotEmpty) {
      data['managerId'] = managerId;
    }

    if (imageKey != null && imageKey!.isNotEmpty) {
      data['imageKey'] = imageKey;
    }

    return data;
  }
}
