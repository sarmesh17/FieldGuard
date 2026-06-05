/// Response for `GET /api/v1/employees/live`.
///
/// Shape:
/// ```json
/// {
///   "count": 1,
///   "employees": [
///     {
///       "employeeId": 2,
///       "employee": { "id": 2, "full_name": "Rajan Kalwar", "employee_code": "EMP_001" },
///       "online": true,
///       "location": null
///     }
///   ]
/// }
/// ```
class LiveEmployeesResponse {
  final int count;
  final List<LiveEmployeeItem> employees;

  LiveEmployeesResponse({required this.count, required this.employees});

  factory LiveEmployeesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['employees'] as List<dynamic>? ?? [];
    return LiveEmployeesResponse(
      count: json['count'] as int? ?? 0,
      employees: list
          .map((e) => LiveEmployeeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LiveEmployeeItem {
  final String employeeId;
  final LiveEmployeeInfo employee;
  final bool online;

  /// Raw location payload. `null` until the device starts reporting.
  /// Kept loosely typed since the live-location schema is not finalized yet.
  final Map<String, dynamic>? location;

  LiveEmployeeItem({
    required this.employeeId,
    required this.employee,
    required this.online,
    this.location,
  });

  factory LiveEmployeeItem.fromJson(Map<String, dynamic> json) {
    return LiveEmployeeItem(
      employeeId: json['employeeId']?.toString() ?? '',
      employee: LiveEmployeeInfo.fromJson(
          (json['employee'] as Map<String, dynamic>?) ?? const {}),
      online: json['online'] as bool? ?? false,
      location: json['location'] is Map<String, dynamic>
          ? json['location'] as Map<String, dynamic>
          : null,
    );
  }
}

class LiveEmployeeInfo {
  final String id;
  final String fullName;
  final String employeeCode;

  LiveEmployeeInfo({
    required this.id,
    required this.fullName,
    required this.employeeCode,
  });

  factory LiveEmployeeInfo.fromJson(Map<String, dynamic> json) {
    return LiveEmployeeInfo(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      employeeCode: json['employee_code'] ?? '',
    );
  }
}
