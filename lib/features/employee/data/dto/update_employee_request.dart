class UpdateEmployeeRequest {
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final bool? isActive;

  UpdateEmployeeRequest({
    this.fullName,
    this.phoneNumber,
    this.email,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (fullName != null) data['fullName'] = fullName;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (email != null) data['email'] = email;
    if (isActive != null) data['isActive'] = isActive;
    
    return data;
  }
}
