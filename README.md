# FieldGuard

> Field-force & sales-team management for distribution businesses — track representatives on the ground, manage shops and tasks, automate visit detection with geofencing, and reconcile collections, all from one Flutter app.

FieldGuard gives admins and managers a live picture of their field team: who is where, which shops were visited, what was collected, and where something looks off. Representatives get a focused, route-driven workflow with automatic check-ins, so the office stays in sync without manual reporting.

---

## ✨ Features

### 👥 Team & Roles
- Role-based experience for **Admin**, **Manager**, **Sales Manager**, and **Field Representative**
- Company registration with **document upload** and an **admin approval** workflow (pending / approved / rejected)
- Create, edit, and view employees and managers; full team management screens
- Secure auth with login, **forgot-password OTP**, and automatic token refresh

### 🗺️ Routes, Geofencing & Live Tracking
- **Mapbox**-powered maps and turn-by-turn directions
- **Automatic geofence** detection — arrival/departure check-ins fire even with the phone in a pocket, via a background foreground-service
- Live team map and per-representative live location
- Tracking history with replayable session routes

### 🏪 Shops & Tasks
- Register shops on the map, edit details, and control visibility
- Assign tasks to representatives, track status, and view task history
- Live task tracking tied to geofence visits

### 💰 Collections & Payments
- Record collections, set shop outstanding/due, and settle balances
- Payment overview with cheque tracking
- **PRO subscription billing** with multiple plans, seat limits, invoices, and QR-based payment

### 🔔 Insights & Alerts
- **Real-time notifications** over Socket.IO plus local heads-up alerts
- Fraud alert review and resolution
- Admin & manager **dashboards** with summary counts and daily/overall progress rings
- Daily reports and visit history

---

## 📸 Screenshots

| Admin Dashboard | Employee Management | Geo-Fencing |
| :---: | :---: | :---: |
| <img src="screenshots/Admin%20DashBoard%20ScreenShot.png" width="220"/> | <img src="screenshots/Employee%20Managemnt%20Screen.png" width="220"/> | <img src="screenshots/Geo-Fencing%20SS.png" width="220"/> |

| Live Location | Task Management | Task Detail |
| :---: | :---: | :---: |
| <img src="screenshots/Live%20Location%20Screen%20Shot.png" width="220"/> | <img src="screenshots/Task%20Management%20ScreenShot.png" width="220"/> | <img src="screenshots/Task%20Detail%20ScreenShot.png" width="220"/> |

---

## 🛠️ Tech Stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart SDK `^3.11.4`) |
| State management | [Riverpod](https://riverpod.dev) (`flutter_riverpod`) |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| Networking | [Dio](https://pub.dev/packages/dio) + interceptors |
| Realtime | [socket_io_client](https://pub.dev/packages/socket_io_client) |
| Maps & directions | [mapbox_maps_flutter](https://pub.dev/packages/mapbox_maps_flutter) |
| Location & geofencing | `geolocator`, `permission_handler`, `flutter_local_notifications` |
| Secure storage | `flutter_secure_storage` |
| Functional core | `dartz` (`Either`-based results) |
| Config | `flutter_dotenv` |

The codebase follows a **feature-first clean architecture** — each feature under `lib/features/` is split into `data/`, `domain/`, and `presentation/` layers, with shared infrastructure in `lib/core/`.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.11.4`)
- Android SDK with **minSdk 21+** (required by Mapbox)
- A **Mapbox** account for an access token

### 1. Clone & install
```bash
git clone git@github.com:sarmesh17/FieldGuard.git
cd FieldGuard
flutter pub get
```

### 2. Configure environment
Create a `.env` file in the project root:

```dotenv
# Public Mapbox token (used to render maps & fetch directions)
MAPBOX_PUBLIC_TOKEN=pk.your_mapbox_public_token_here
```

> Mapbox also needs a **secret download token** configured in `android/gradle.properties` / `~/.gradle/gradle.properties` to fetch the SDK at build time. See the [Mapbox Flutter setup guide](https://docs.mapbox.com/android/maps/guides/install/).

The app talks to the hosted backend at `https://fieldguard-be.onrender.com` (configured in `lib/core/constant/api_constant.dart`).

### 3. Run
```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── core/                  # Shared infrastructure
│   ├── constant/          # API endpoints, strings
│   ├── networks/          # Dio client + interceptors
│   ├── responsive/        # Responsive layout helpers
│   ├── router/            # go_router config
│   ├── services/          # Auth, tokens, notifications
│   └── utils/             # Results, runners, formatters
│
└── features/              # Feature-first modules (data / domain / presentation)
    ├── auth/              # Login, signup, approval, OTP
    ├── dashboard/         # Admin & manager dashboards
    ├── team/              # Employee & manager management
    ├── shops/             # Shop registration & management
    ├── tasks/             # Task assignment & tracking
    ├── routes/            # Mapbox routes & directions
    ├── auto_geofence/     # Background geofence detection
    ├── live_tracking/     # Live location & history
    ├── collections/       # Payments & settlements
    ├── notifications/     # Realtime & local alerts
    ├── fraud_alert_screen/# Fraud review
    └── ...
```

---

## 🤝 Contributing

1. Branch off `main` (e.g. `feature/your-feature`)
2. Keep changes within the relevant feature module and follow the existing `data` / `domain` / `presentation` split
3. Run `flutter analyze` and `flutter test` before opening a PR

---

## 📄 License

This project is currently private and not published to pub.dev (`publish_to: "none"`). Add a license here before making it public.
