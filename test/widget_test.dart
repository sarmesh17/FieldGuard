import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash screen renders app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginNotifierProvider.overrideWith(
            (ref) => _FakeLoginNotifier(),
          ),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('FieldGuard'), findsOneWidget);
  });
}

class _FakeLoginNotifier extends StateNotifier<LoginState> {
  _FakeLoginNotifier() : super(const LoginInitial());
}
