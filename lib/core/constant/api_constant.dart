class ApiConstant {
  static const String baseUrl = "https://fieldguard-be.onrender.com";

  // ─── API Endpoints ─────────────────────────────────────────────────────────────
  static const String loginEndpoint = "$baseUrl/api/v1/auth/login";
  // The endpoint for refreshing tokens
  static const String refreshTokenEndpoint =
      "$baseUrl/api/v1/auth/refresh-token";

  // The endpoint for company registration
  static const String companyRegistration = "$baseUrl/api/v1/company/register";

  // The endpoint for creating employees
  static const String createEmployeeEndpoint = "$baseUrl/api/v1/employees";

  // The endpoint for creating managers
  static const String createManagerEndpoint = "$baseUrl/api/v1/managers";

  // The endpoint for getting list of employees
  static const String getEmployeesEndpoint = "$baseUrl/api/v1/employees";

  // The endpoint for getting list of managers
  static const String getManagersEndpoint = "$baseUrl/api/v1/managers";

  // Timeouts (Good to keep centralized)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}
