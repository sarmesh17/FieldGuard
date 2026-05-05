import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/login_screen/login_provider.dart';
import 'presentation/screens/onboarding_screen/onboarding_provider.dart';
import 'presentation/screens/splash_screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: MaterialApp(
        title: 'FieldGuard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
