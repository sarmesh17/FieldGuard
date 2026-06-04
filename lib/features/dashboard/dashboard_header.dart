import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/dashboard/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// Top row of the dashboard's gradient hero: avatar + greeting + name + role
/// badge + notification bell. Rendered white-on-gradient.
class ManagerHeaderSection extends ConsumerWidget {
  const ManagerHeaderSection({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _greetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '👋';
    return '🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginNotifierProvider);
    final dashboardState = ref.watch(dashboardSummaryProvider);

    // Derive role from login state (fresh login) with a fallback to the
    // summary payload (survives app relaunch when login state is reset).
    String role = '';
    if (loginState is LoginSuccess) {
      role = loginState.response.user.role;
    }

    String name = '';
    String? profileImageUrl;

    if (loginState is LoginSuccess &&
        loginState.response.user.name.isNotEmpty) {
      name = loginState.response.user.name;
    }

    dashboardState.whenData((summary) {
      if (summary.fullName.isNotEmpty) name = summary.fullName;
      // Survives app relaunch — login state is reset, but the summary carries
      // the role so the badge keeps showing.
      if (role.isEmpty && summary.role.isNotEmpty) role = summary.role;
      if (summary.profileImage != null) {
        final img = summary.profileImage!;
        profileImageUrl = img.startsWith('http')
            ? img
            : 'https://fieldguard-be.onrender.com/$img';
      }
    });

    final isLoading = dashboardState.isLoading;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Avatar with soft white ring ──────────────────────────────────
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: profileImageUrl != null
                ? Image.network(
                    profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, _) => _initialsWidget(name),
                  )
                : _initialsWidget(name),
          ),
        ),

        const SizedBox(width: 14),

        // ── Greeting + name ──────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()} ${_greetingEmoji()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 3),
              isLoading && name.isEmpty
                  ? Container(
                      height: 22,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  : Row(
                      children: [
                        Flexible(
                          child: Text(
                            name.isNotEmpty ? name : '...',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (role.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _roleBadge(role),
                        ],
                      ],
                    ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // ── Notification bell (frosted) ──────────────────────────────────
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _roleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _initialsWidget(String name) {
    return Container(
      color: AppColors.teal,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
