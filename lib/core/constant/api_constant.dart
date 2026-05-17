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

  // The endpoint for live/online employees (Redis-backed).
  // ADMIN sees whole company; MANAGER sees only their team.
  static const String getLiveEmployeesEndpoint =
      "$baseUrl/api/v1/employees/live";

  // The endpoint for getting list of managers
  static const String getManagersEndpoint = "$baseUrl/api/v1/managers";

  // The endpoint for getting shops hierarchy / creating a shop
  static const String getShopsEndpoint = "$baseUrl/api/v1/shops";

  // The endpoint for requesting a pre-signed S3 upload URL
  static const String presignedUrlEndpoint = "$baseUrl/api/v1/uploads/presigned-url";

  // The endpoint for updating a shop (append /{id})
  static const String updateShopEndpoint = "$baseUrl/api/v1/shops";

  // The endpoint for getting admin profile
  static const String getProfileEndpoint = "$baseUrl/api/v1/auth/me";

  // The endpoint for updating admin profile
  static const String updateProfileEndpoint = "$baseUrl/api/v1/auth/profile";

  // The endpoint for listing / creating tasks
  static const String tasksEndpoint = "/api/v1/tasks";

  // Timeouts (Good to keep centralized)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}