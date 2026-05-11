import 'package:fieldguard/presentation/notifiers/signup_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' hide Provider;
import '../../presentation/notifiers/login_notifier.dart';
import '../../presentation/screens/login_screen/login_screen.dart';
import '../../presentation/screens/signup_screen/signup_screen.dart';
import '../../presentation/screens/splash_screen/splash_screen.dart';

// ─── Route paths ──────────────────────────────────────────────────────────────

/// Single source of truth for all route paths.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
}

// ─── Router provider ──────────────────────────────────────────────────────────

/// Riverpod provider for the [GoRouter] instance.
///
/// Declared as a [Provider] so the router is created once and shared.
/// The router listens to [loginNotifierProvider] to redirect authenticated
/// users away from auth screens.
final goRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state so the router refreshes when the user signs in/out.
  final isAuthenticated = ref.watch(
    loginNotifierProvider.select((state) => state.user != null),
  );

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    // ── Redirect logic ──────────────────────────────────────────────────────
    redirect: (context, state) {
      final isOnAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      // If authenticated and trying to visit auth screens
      if (isAuthenticated && isOnAuthRoute) {
        return AppRoutes.login;
      }

      return null;
    },
    // ── Routes ──────────────────────────────────────────────────────────────
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: SignupScreen()),
      ),
    ],

    // ── Error page ──────────────────────────────────────────────────────────
    errorPageBuilder: (context, state) =>
        _fadePage(state: state, child: const SplashScreen()),
  );
});

// ─── Transition helpers ───────────────────────────────────────────────────────

CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
  );
}
