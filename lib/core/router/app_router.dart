import 'package:fieldguard/core/router/app_routes.dart';
import 'package:fieldguard/features/auth/approval/data/dto/company_approval_response.dart';
import 'package:fieldguard/features/auth/approval/presentation/screens/account_rejected_screen.dart';
import 'package:fieldguard/features/auth/approval/presentation/screens/pending_approval_screen.dart';
import 'package:fieldguard/features/admin_profile/admin_profile.dart';
import 'package:fieldguard/features/tasks/presentation/screens/tasks_list_screen.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/screens/forgot_password_screen.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/screens/reset_password_screen.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/auth/login/presentation/screens/login_screen.dart';
import 'package:fieldguard/features/auth/signup/presentation/screens/registration_success_screen.dart';
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
/// The router is built **once** and shared. Auth-state changes drive
/// redirect re-evaluation through [refreshListenable] — they must not
/// recreate the router, or every intermediate state during a login attempt
/// (`LoginLoading`, `LoginFailure`, …) would reset navigation back to
/// [AppRoutes.splash].
final goRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _RiverpodGoRouterRefresh(ref);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: authListenable,

    // ── Redirect logic ──────────────────────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(loginNotifierProvider);
      final isOnAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.resetPassword ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.registrationSuccess;

      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      // While the session/approval check is in flight, stay on splash.
      if (authState is LoginChecking) {
        return AppRoutes.splash;
      }

      // Not signed in → only auth/splash screens are reachable.
      if (authState is! LoginSuccess) {
        if (!isOnAuthRoute && !isOnSplash) return AppRoutes.login;
        return null;
      }

      // Signed in: gate on the company approval status. Pending/rejected (and
      // any unrecognised status) users are confined to their gate screen and
      // cannot reach the app shell; approved users are sent into the app.
      final isOnGateScreen =
          state.matchedLocation == AppRoutes.pendingApproval ||
          state.matchedLocation == AppRoutes.accountRejected;

      switch (authState.approvalStatus) {
        case ApprovalStatus.rejected:
          return state.matchedLocation == AppRoutes.accountRejected
              ? null
              : AppRoutes.accountRejected;

        case ApprovalStatus.pendingApproval:
        case ApprovalStatus.unknown:
          return state.matchedLocation == AppRoutes.pendingApproval
              ? null
              : AppRoutes.pendingApproval;

        case ApprovalStatus.approved:
          // Approved users shouldn't sit on auth/splash/gate screens.
          if (isOnAuthRoute || isOnSplash || isOnGateScreen) {
            return AppRoutes.dashboard;
          }
          return null;
      }
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
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const ResetPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: SignupScreen()),
      ),
      GoRoute(
        path: AppRoutes.registrationSuccess,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const RegistrationSuccessScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const PendingApprovalScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountRejected,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const AccountRejectedScreen(),
        ),
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

// ─── Riverpod → GoRouter refresh adapter ──────────────────────────────────────

/// Bridges a Riverpod provider into [GoRouter.refreshListenable].
///
/// GoRouter re-evaluates its redirect whenever this `Listenable` notifies, so
/// the router instance itself never has to be rebuilt — auth-state changes
/// stay non-disruptive to in-flight navigation.
class _RiverpodGoRouterRefresh extends ChangeNotifier {
  _RiverpodGoRouterRefresh(Ref ref) {
    _removeListener = ref.listen<LoginState>(
      loginNotifierProvider,
      (_, _) => notifyListeners(),
    ).close;
  }

  late final void Function() _removeListener;

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }
}
