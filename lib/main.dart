
import 'package:fieldguard/presentation/screens/manager_panel/manager_panel.dart';
import 'package:fieldguard/presentation/screens/manager_profile/manager_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The router is provided by Riverpod so it can react to auth state changes.
    final router = ref.watch(goRouterProvider);

    // return MaterialApp.router(
    //   title: 'FieldGuard',
    //   debugShowCheckedModeBanner: false,
    //   theme: AppTheme.light,
    //   routerConfig: router,
    // );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: ManagerProfileScreen(),
    );
  }
}
