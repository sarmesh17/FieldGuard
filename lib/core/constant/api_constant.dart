class ApiConstant {
  static const String baseUrl = "https://fieldguard.duckdns.org";

  /// Resolves a stored asset value (e.g. a profile-image path) to an
  /// absolute URL: already-absolute values pass through, relative paths
  /// join onto [baseUrl]. The single place the asset host lives.
  static String imageUrl(String pathOrUrl) =>
      pathOrUrl.startsWith('http') ? pathOrUrl : '$baseUrl/$pathOrUrl';

  // ─── API Endpoints ─────────────────────────────────────────────────────────────
  static const String loginEndpoint = "$baseUrl/api/v1/auth/login";
  // The endpoint for refreshing tokens
  static const String refreshTokenEndpoint =
      "$baseUrl/api/v1/auth/refresh-token";

  // OTP-based password reset (ADMIN only). Both are public — no auth token.
  // Step 1: request an OTP by phone number.
  static const String forgotPasswordEndpoint =
      "$baseUrl/api/v1/auth/forgot-password";
  // Step 2: submit the OTP + new password. A 401 here means a bad/expired OTP,
  // NOT a session problem.
  static const String resetPasswordEndpoint =
      "$baseUrl/api/v1/auth/reset-password";

  // The endpoint for company registration
  static const String companyRegistration = "$baseUrl/api/v1/company/register";

  // The endpoint for the current legal (Terms/Privacy) version — public, no auth.
  // Source of truth for the `termsVersion` sent on register/login.
  static const String legalVersionEndpoint = "$baseUrl/api/v1/legal/version";

  // The full Terms & Privacy content — public, no auth. Rendered verbatim.
  static const String legalContentEndpoint = "$baseUrl/api/v1/legal/content";

  // Registers this device's FCM push token against the signed-in user (auth).
  static const String pushTokenEndpoint = "$baseUrl/api/v1/device/push-token";

  // In-app notification center (auth; approved company only).
  static const String notificationsEndpoint = "$baseUrl/api/v1/notifications";

  // The endpoint for confirming company documents (PATCH)
  static const String companyEndpoint = "$baseUrl/api/v1/company";

  // ─── Subscription / billing (company ADMIN) ─────────────────────────────────
  // Current plan + seat usage + available plans + payment QR.
  static const String companySubscriptionEndpoint =
      "$baseUrl/api/v1/company/subscription";
  // Submit a PRO upgrade request (months + payment proof image key).
  static const String subscriptionRequestEndpoint =
      "$baseUrl/api/v1/company/subscription/request";
  // List upgrade requests (newest first) — polled while one is pending.
  static const String subscriptionRequestsEndpoint =
      "$baseUrl/api/v1/company/subscription/requests";
  // Subscription invoices (auto-generated on payment approval) — read-only.
  static const String subscriptionInvoicesEndpoint =
      "$baseUrl/api/v1/company/subscription/invoices";

  // ─── ENTERPRISE "Talk to us" call requests (company ADMIN) ──────────────────
  // Submit a call-back lead (contact phone + optional staff count / note). Only
  // one PENDING allowed at a time → a 409 means one is already open.
  static const String enterpriseInquiryEndpoint =
      "$baseUrl/api/v1/company/subscription/enterprise-inquiry";
  // List this company's enterprise inquiries (newest first) — track status.
  static const String enterpriseInquiriesEndpoint =
      "$baseUrl/api/v1/company/subscription/enterprise-inquiries";

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

  // The endpoint for updating manager's own profile (MANAGER only)
  static const String updateManagerProfileEndpoint = "$baseUrl/api/v1/managers/profile";


  // The endpoint for listing / creating tasks
  static const String tasksEndpoint = "/api/v1/tasks";

  // The endpoint for dashboard aggregated summary (lifetime task totals)
  static const String dashboardSummaryEndpoint = "$baseUrl/api/v1/dashboard/summary";

  // The endpoint for tasks due TODAY (daily progress) — same bucket shape
  static const String dashboardTodayTasksEndpoint =
      "$baseUrl/api/v1/dashboard/today-tasks";


  // The endpoint for reporting automatic geofence visits
  static const String geofenceVisitsEndpoint =
      "$baseUrl/api/v1/geofence-visits";

  // The endpoint for recording a cash/cheque collection (EMPLOYEE/MANAGER only)
  static const String collectionsEndpoint = "$baseUrl/api/v1/collections";

  // Timeouts (Good to keep centralized)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}