import 'package:fieldguard/presentation/screens/login_screen/login_provider.dart';
import 'package:fieldguard/presentation/screens/login_screen/login_screen.dart';
import 'package:fieldguard/presentation/screens/onboarding_screen/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fieldguard/presentation/screens/onboarding_screen/onboarding_provider.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,

      home: ChangeNotifierProvider(
        create: (_) => OnboardingProvider(),
        child: OnboardingScreen(),
      ),
    );
  }
}
