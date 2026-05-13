class ApiConstant {
  static const String baseUrl = "https://fieldguard-be.onrender.com";

  // ─── API Endpoints ─────────────────────────────────────────────────────────────
  static const String loginEndpoint = "$baseUrl/api/v1/auth/login";
  // The endpoint for refreshing tokens
  static const String refreshTokenEndpoint =
      "$baseUrl/api/v1/auth/refresh-token";

  // The endpoint for company registration
  static const String companyRegistration = "$baseUrl/api/v1/company/register";

  // Timeouts (Good to keep centralized)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}
