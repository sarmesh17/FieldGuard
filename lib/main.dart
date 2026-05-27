import 'package:fieldguard/core/services/notification_service.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/auto_geofence/presentation/active_tasks_provider.dart';
import 'package:fieldguard/features/auto_geofence/service/auto_geofence_service.dart';
import 'package:fieldguard/features/routes/presentation/providers/route_tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_PUBLIC_TOKEN']!);
  // Register the notification channel + prompt for permission before any
  // call site (e.g. geofence enter/exit) tries to show one.
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    // Couple the auto-geofence tracker's lifetime to the auth session:
    // start once authenticated (including a restored session), stop on
    // logout / session expiry. Detection is never driven from the UI —
    // this only toggles the service on/off.
    ref.listen<LoginState>(loginNotifierProvider, (previous, next) {
      if (next is LoginSuccess) {
        AutoGeofenceService.instance.start();
        // Activate the reactive task→geofence bridge (keeps the active-tasks
        // source alive and pushes arm/disarm changes the instant they happen).
        ref.read(geofenceTaskSyncProvider);
        // Mount the enter/exit → notification + UI bridge app-wide. The user
        // is rarely on the Routes screen when they walk into a geofence
        // (phone in pocket), so this must outlive that screen's lifecycle.
        ref.read(geofenceEventBridgeProvider);
      } else if (next is LoginInitial || next is LoginFailure) {
        AutoGeofenceService.instance.stop();
        // Tear the bridges down — clears socket subs, timers, and detaches
        // the service callbacks set by the event bridge.
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
