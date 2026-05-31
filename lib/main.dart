import 'package:fieldguard/core/security/root_detection_service.dart';
import 'package:fieldguard/core/security/security_blocked_screen.dart';
import 'package:fieldguard/core/services/background_location_service.dart';
import 'package:fieldguard/core/services/notification_service.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/auto_geofence/presentation/active_tasks_provider.dart';
import 'package:fieldguard/features/routes/presentation/providers/route_tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Block rooted / jailbroken devices before initializing anything else: a
  // compromised device shows the security screen and the real app (router,
  // providers, background services) is never mounted.
  if (await RootDetectionService.isDeviceCompromised()) {
    runApp(const SecurityBlockedApp());
    return;
  }

  await dotenv.load(fileName: '.env');
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_PUBLIC_TOKEN']!);
  // Register the notification channels + prompt for permission before any
  // call site (e.g. geofence enter/exit) tries to show one.
  await NotificationService.instance.init();
  // Register the background-service isolate (does NOT start it — start/stop is
  // driven by whether a task is IN_PROGRESS). Geofence detection runs inside
  // this isolate so enter/exit alerts survive the app being swipe-killed.
  await BackgroundLocationService.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    // Couple the auto-geofence tracker's lifetime to the auth session.
    // Detection itself runs inside the background-service isolate (so it
    // survives an app-kill); the UI never drives it. On login we just mount
    // the bridges that (a) start/stop the isolate as IN_PROGRESS tasks come
    // and go, and (b) relay the isolate's enter/exit events into the UI.
    ref.listen<LoginState>(loginNotifierProvider, (previous, next) {
      if (next is LoginSuccess) {
        // Activate the reactive task→service bridge (starts/stops the bg
        // service the instant the manager's IN_PROGRESS tasks change).
        ref.read(geofenceTaskSyncProvider);
        // Mount the enter/exit → notification + UI bridge app-wide. The user
        // is rarely on the Routes screen when they walk into a geofence
        // (phone in pocket), so this must outlive that screen's lifecycle.
        ref.read(geofenceEventBridgeProvider);
      } else if (next is LoginInitial || next is LoginFailure) {
        // Stop the background service and tear the bridges down.
        BackgroundLocationService.stop();
        ref.invalidate(geofenceTaskSyncProvider);
        ref.invalidate(geofenceEventBridgeProvider);
      }
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      routerConfig: router,
    );
  }
}
