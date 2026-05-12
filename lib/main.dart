import 'package:fieldguard/presentation/screens/dashboard_sscreen/admin_dashboard/dashboard_screen.dart';
import 'package:fieldguard/presentation/notifiers/signup_notifier.dart';
import 'package:fieldguard/presentation/screens/dashboard_sscreen/manager_dashboard/mdashboard_screen.dart';
import 'package:fieldguard/presentation/screens/fraud_alert_screen/fraud_alert_screen.dart';
import 'package:fieldguard/presentation/screens/live_team_map_screen/live_team_map_screen.dart';
import 'package:fieldguard/presentation/screens/payment_overview_screen/payment_overview_screen.dart';
import 'package:fieldguard/presentation/screens/representative_detail_screen.dart/representative_detail_screen.dart';
import 'package:fieldguard/presentation/screens/signup_screen/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The router is provided by Riverpod so it can react to auth state changes.
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'FieldGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );

    
  }
}
