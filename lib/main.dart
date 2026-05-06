import 'package:fieldguard/presentation/screens/signup_screen/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    // ProviderScope is the Riverpod equivalent of MultiProvider —
    // it must wrap the entire widget tree.
    const ProviderScope(child: MyApp()),
  );
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

    return MaterialApp(home: SignUpScreen());
  }
}
