import 'package:fieldguard/core/router/app_routes.dart';
import 'package:fieldguard/features/admin_profile/admin_profile.dart';
import 'package:fieldguard/features/tasks/presentation/screens/tasks_list_screen.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/auth/login/presentation/screens/login_screen.dart';
import 'package:fieldguard/features/auth/signup/presentation/screens/signup_screen.dart';
import 'package:fieldguard/features/dashboard/dashboard_screen.dart';
import 'package:fieldguard/features/routes/presentation/screens/routes_screen.dart';
import 'package:fieldguard/features/shops/data/dto/shops_hierarchy_response.dart';
import 'package:fieldguard/features/shops/presentation/screens/shops_screen.dart';
import 'package:fieldguard/features/shops/presentation/screens/update_shop_screen.dart';
import 'package:fieldguard/features/splash_screen/splash_screen.dart';
import 'package:fieldguard/features/team/presentation/screens/team_management_screen.dart';
import 'package:fieldguard/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─── Router provider ──────────────────────────────────────────────────────────

/// Riverpod provider for the [GoRouter] instance.
///
/// Declared as a [Provider] so the router is created once and shared.
/// The router listens to [loginNotifierProvider] to redirect authenticated
/// users away from auth screens.
final goRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state so the router refreshes when the user signs in/out.
  final isAuthenticated = ref.watch(
    loginNotifierProvider.select((state) => state is LoginSuccess),
  );

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    // ── Redirect logic ──────────────────────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(loginNotifierProvider);
      final isOnAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;
      
      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      // If still checking auth state, stay on splash
      if (authState is LoginChecking) {
        return AppRoutes.splash;
      }

      // If authenticated and trying to visit auth screens or splash
      if (isAuthenticated && (isOnAuthRoute || isOnSplash)) {
        return AppRoutes.dashboard;
      }

      // If not authenticated and not on an auth/splash screen, go to login
      if (!isAuthenticated && !isOnAuthRoute && !isOnSplash) {
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
      GoRoute(
        path: AppRoutes.tasks,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const TasksListScreen()),
      ),

      // ── Bottom Navigation Shell ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: Dashboard()),
              ),
            ],
          ),
          // Shops Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.shops,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ShopsScreen()),
                routes: [
                  GoRoute(
                    path: 'edit/:id',
                    pageBuilder: (context, state) {
                      final shop = state.extra as Shop;
                      return _slidePage(
                        state: state,
                        child: UpdateShopScreen(shop: shop),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Routes Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.routes,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: RoutesScreen()),
              ),
            ],
          ),
          // Team Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.team,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TeamManagementScreen()),
              ),
            ],
          ),
          // Profile Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],

    // ── Error page ──────────────────────────────────────────────────────────
    errorPageBuilder: (context, state) =>
        _fadePage(state: state, child: const SplashScreen()),
  );
});

// ─── Scaffold with Bottom Navigation ──────────────────────────────────────────

/// Scaffold with bottom navigation bar that wraps the navigation shell
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

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
