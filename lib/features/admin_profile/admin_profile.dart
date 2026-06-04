import 'dart:math' as math;

import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/admin_profile/presentation/providers/profile_provider.dart';
import 'package:fieldguard/features/admin_profile/presentation/providers/profile_state.dart';
import 'package:fieldguard/features/admin_profile/presentation/providers/profile_stats_provider.dart';
import 'package:fieldguard/features/admin_profile/presentation/screens/personal_information_screen.dart';
import 'package:fieldguard/features/admin_profile/section_card.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/employee/presentation/screens/create_employee_screen.dart';
import 'package:fieldguard/features/legal/presentation/screens/legal_screen.dart';
import 'package:fieldguard/features/manager/presentation/screens/create_manager_screen.dart';
import 'package:fieldguard/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();

    // Fetch profile data and real stats when screen loads
    Future.microtask(() {
      ref.read(profileNotifierProvider.notifier).fetchProfile();
      ref.read(profileStatsNotifierProvider.notifier).fetch();
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToPersonalInformation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalInformationScreen(),
      ),
    );
  }

  void _navigateToLegal(LegalTab tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegalScreen(initialTab: tab),
      ),
    );
  }

  void _navigateToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    // Show loading or error states
    if (profileState is ProfileLoading) {
      return const Scaffold(
        backgroundColor: AppColors.white2,
        body: SkeletonDetail(),
      );
    }

    if (profileState is ProfileFailure) {
      return Scaffold(
        backgroundColor: AppColors.white2,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: w * 0.15,
                color: Colors.red.shade400,
              ),
              SizedBox(height: h * 0.02),
              Text(
                'Failed to load profile',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: h * 0.01),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.1),
                child: Text(
                  profileState.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.035,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(height: h * 0.03),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(profileNotifierProvider.notifier).fetchProfile();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.08,
                    vertical: h * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get profile data
    final profile = profileState is ProfileSuccess
        ? profileState.profile
        : profileState is ProfileUpdateSuccess
        ? profileState.profile
        : null;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.white2,
        body: SkeletonDetail(),
      );
    }

    // Only an admin can create managers — that endpoint is admin-only.
    final isManager = profile.role.toUpperCase() == 'MANAGER';

    return Scaffold(
      backgroundColor: AppColors.white2,
      // Suppress the Android stretch/glow overscroll so pulling the screen
      // doesn't drag the green header and tear the layout.
      body: ScrollConfiguration(
        behavior: const _NoOverscrollBehavior(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;
            // Base every proportional size on the SHORTER side. In portrait
            // this equals the width (behaviour unchanged); in landscape it
            // switches to the height, so the avatar/text/header don't blow up
            // and tear the layout.
            final unit = math.min(maxW, maxH);
            final avatarSize = unit * 0.28;
            final headerHeight = math.max(maxH * 0.30, avatarSize * 1.9);
            // The header is full-bleed, but the cards below are capped so they
            // don't stretch huge on wide/landscape screens — they stay a
            // comfortable phone-width and centre instead.
            final contentMaxW = math.min(maxW, 600.0);

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Header + Avatar overlap
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FadeTransition(
                        opacity: _headerFade,
                        child: _buildGradientHeader(maxW, unit, headerHeight),
                      ),
                      Positioned(
                        bottom: -(avatarSize / 2),
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildAvatar(
                                avatarSize,
                                unit,
                                profile.profileImage,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: avatarSize / 2 + unit * 0.05),
                  // Everything below the header is capped to a comfortable
                  // width and centred, so cards don't stretch on landscape.
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxW),
                      child: Column(
                        children: [
                          // Name, email, badge
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildProfileInfo(unit, profile),
                            ),
                          ),
                          SizedBox(height: unit * 0.025),
                          // Stats card
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: unit * 0.05,
                            ),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildStatsCard(unit, isManager),
                            ),
                          ),
                          SizedBox(height: unit * 0.022),
                          // Admin Tools
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: unit * 0.05,
                            ),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SectionCard(
                                  title: 'ADMIN TOOLS',
                                  highlighted: true,
                                  items: [
                                    SectionTile(
                                      icon: Icons.person_add_alt_1_rounded,
                                      title: 'Create New Employee',
                                      iconColor: AppColors.green,
                                      iconBg: AppColors.green15,
                                      isAction: true,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CreateEmployeeScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    if (!isManager)
                                      SectionTile(
                                        icon: Icons.supervisor_account_rounded,
                                        title: 'Create New Manager',
                                        iconColor: AppColors.blue,
                                        iconBg: AppColors.blue7,
                                        isAction: true,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const CreateManagerScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: unit * 0.018),
                          // Subscription — ADMIN only (plan + seats + billing).
                          if (!isManager)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: unit * 0.05,
                              ),
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: SectionCard(
                                    title: 'SUBSCRIPTION',
                                    items: [
                                      SectionTile(
                                        icon: Icons.workspace_premium_rounded,
                                        title: 'Plan & Billing',
                                        iconColor: AppColors.green,
                                        iconBg: AppColors.green15,
                                        onTap: _navigateToSubscription,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (!isManager) SizedBox(height: unit * 0.018),
                          // Account
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: unit * 0.05,
                            ),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SectionCard(
                                  title: 'ACCOUNT',
                                  items: [
                                    SectionTile(
                                      icon: Icons.person_outline_rounded,
                                      title: 'Personal Information',
                                      onTap: _navigateToPersonalInformation,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: unit * 0.018),
                          // Legal
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: unit * 0.05,
                            ),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SectionCard(
                                  title: 'LEGAL',
                                  items: [
                                    SectionTile(
                                      icon: Icons.description_outlined,
                                      title: 'Terms & Conditions',
                                      onTap: () =>
                                          _navigateToLegal(LegalTab.terms),
                                    ),
                                    SectionTile(
                                      icon: Icons.privacy_tip_outlined,
                                      title: 'Privacy Policy',
                                      onTap: () =>
                                          _navigateToLegal(LegalTab.privacy),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: unit * 0.035),
                          // Sign Out
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: unit * 0.05,
                            ),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildSignOutButton(unit),
                            ),
                          ),
                          SizedBox(height: unit * 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // [fullW] is the real viewport width (the header is full-bleed). [unit] is
  // the shorter screen side — all proportional sizes (fonts, icons, circles,
  // padding) scale off it so they don't blow up in landscape.
  Widget _buildGradientHeader(double fullW, double unit, double headerHeight) {
    return ClipPath(
      clipper: _ProfileHeaderClipper(),
      child: Container(
        height: headerHeight,
        width: fullW,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.green8, AppColors.green, AppColors.green3],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -unit * 0.07,
              right: -unit * 0.12,
              child: _decorCircle(unit * 0.55, 0.07),
            ),
            Positioned(
              top: unit * 0.04,
              right: fullW * 0.1,
              child: _decorCircle(unit * 0.18, 0.05),
            ),
            Positioned(
              top: unit * 0.02,
              left: -unit * 0.07,
              child: _decorCircle(unit * 0.38, 0.05),
            ),
            Positioned(
              bottom: unit * 0.14,
              left: fullW * 0.25,
              child: _decorCircle(unit * 0.1, 0.04),
            ),
            // Top bar
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: unit * 0.04,
                  vertical: unit * 0.01,
                ),
                child: Row(
                  children: [
                    Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: unit * 0.05,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(double avatarSize, double w, String? profileImage) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: profileImage != null
            ? Image.network(
                profileImage.startsWith('http')
                    ? profileImage
                    : 'https://fieldguard-be.onrender.com/$profileImage',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.grey4,
                    child: Icon(
                      Icons.person_rounded,
                      size: w * 0.15,
                      color: AppColors.grey2,
                    ),
                  );
                },
              )
            : Container(
                color: AppColors.grey4,
                child: Icon(
                  Icons.person_rounded,
                  size: w * 0.15,
                  color: AppColors.grey2,
                ),
              ),
      ),
    );
  }

  Widget _buildProfileInfo(double w, profile) {
    return Column(
      children: [
        Text(
          profile.fullName,
          style: TextStyle(
            fontSize: w * 0.068,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: w * 0.018),
        Text(
          profile.email ?? profile.company?.email ?? 'No email',
          style: TextStyle(
            fontSize: w * 0.037,
            color: AppColors.grey5,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: w * 0.04),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.055,
            vertical: w * 0.022,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.purple2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(w * 0.1),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.38),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                size: w * 0.038,
                color: Colors.white,
              ),
              SizedBox(width: w * 0.015),
              Text(
                profile.role.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: w * 0.033,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(double w, bool isManager) {
    final statsState = ref.watch(profileStatsNotifierProvider);
    final loading = statsState is ProfileStatsLoading;
    final stats = statsState is ProfileStatsLoaded
        ? statsState.stats
        : ProfileStats.empty;

    // A MANAGER has no manager count (admin-only endpoint), so that column is
    // dropped entirely for them rather than shown as an empty dash.
    final items = <Widget>[
      if (!isManager)
        Expanded(
          child: _StatItem(
            value: stats.managers,
            title: 'Managers',
            loading: loading,
            delay: 300,
          ),
        ),
      Expanded(
        child: _StatItem(
          value: stats.reps,
          title: 'Reps',
          loading: loading,
          delay: 500,
        ),
      ),
      Expanded(
        child: _StatItem(
          value: stats.shops,
          title: 'Shops',
          loading: loading,
          delay: 700,
        ),
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: w * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const _StatsVerticalDivider(),
            items[i],
          ],
        ],
      ),
    );
  }

  Widget _buildSignOutButton(double w) {
    return GestureDetector(
      onTap: () async {
        // Show confirmation dialog
        final shouldLogout = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizeConfig.scale(28)),
              ),
              elevation: 8,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SizeConfig.scale(28)),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.white16,
                      AppColors.white,
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(SizeConfig.scale(28)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with gradient background
                      Container(
                        width: SizeConfig.scale(72),
                        height: SizeConfig.scale(72),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.green,
                              AppColors.green3,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.green.withValues(alpha: 0.3),
                              blurRadius: SizeConfig.scale(16),
                              offset: Offset(0, SizeConfig.scale(6)),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: SizeConfig.scale(36),
                        ),
                      ),
                      SizedBox(height: SizeConfig.scale(24)),
                      // Title
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: SizeConfig.scaledFontSize(24),
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: SizeConfig.scale(12)),
                      // Message
                      Text(
                        'Are you sure you want to sign out?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: SizeConfig.scaledFontSize(15),
                          color: AppColors.grey,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: SizeConfig.scale(32)),
                      // Buttons
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
                                border: Border.all(
                                  color: AppColors.grey3,
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context, false),
                                  borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: SizeConfig.scale(16),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: SizeConfig.scaledFontSize(16),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: SizeConfig.scale(12)),
                          // Sign Out Button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.red3,
                                    AppColors.red15,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.red3.withValues(alpha: 0.4),
                                    blurRadius: SizeConfig.scale(12),
                                    offset: Offset(0, SizeConfig.scale(4)),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context, true),
                                  borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: SizeConfig.scale(16),
                                    ),
                                    child: Text(
                                      'Sign Out',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: SizeConfig.scaledFontSize(16),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        if (shouldLogout == true && mounted) {
          // Perform logout
          ref.read(loginNotifierProvider.notifier).logout();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: w * 0.045),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: AppColors.red19, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.red3.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: AppColors.red3,
              size: w * 0.055,
            ),
            SizedBox(width: w * 0.025),
            Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.red3,
                fontSize: w * 0.044,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Removes the Android stretch/glow overscroll indicator so an overscroll
/// can't drag the green header or expose the grey background behind it.
class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 55);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 25,
      size.width,
      size.height - 55,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _StatsVerticalDivider extends StatelessWidget {
  const _StatsVerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: MediaQuery.of(context).size.width * 0.12,
      color: AppColors.grey4,
    );
  }
}

/// A single stat (Managers / Reps / Shops) on the profile stats card.
///
/// Animates a count-up to [value] once loaded. While [loading] it shows a
/// muted "…", and if [value] is null (the count failed to load) it shows a
/// dash — it never fabricates a number.
class _StatItem extends StatefulWidget {
  final int? value;
  final String title;
  final bool loading;
  final int delay;

  const _StatItem({
    required this.value,
    required this.title,
    required this.loading,
    this.delay = 0,
  });

  @override
  State<_StatItem> createState() => _StatItemState();
}

class _StatItemState extends State<_StatItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(covariant _StatItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Count arrived (or changed) after the async fetch resolved — animate now.
    if (oldWidget.value != widget.value) {
      _controller.reset();
      _maybeAnimate();
    }
  }

  void _maybeAnimate() {
    final value = widget.value;
    if (value == null) return;
    _animation = Tween<double>(
      begin: 0,
      end: value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final valueStyle = TextStyle(
      fontSize: w * 0.072,
      fontWeight: FontWeight.w800,
      color: AppColors.green,
      letterSpacing: -0.5,
    );

    Widget valueText;
    if (widget.loading) {
      valueText = Text('…', style: valueStyle);
    } else if (widget.value == null || _animation == null) {
      // Count failed to load — show a dash rather than a fake number.
      valueText = Text('—', style: valueStyle);
    } else {
      valueText = AnimatedBuilder(
        animation: _animation!,
        builder: (context, child) =>
            Text(_animation!.value.toInt().toString(), style: valueStyle),
      );
    }

    return Column(
      children: [
        // FittedBox scales the number down on very narrow columns / large
        // system font scales instead of overflowing.
        FittedBox(fit: BoxFit.scaleDown, child: valueText),
        SizedBox(height: w * 0.012),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: w * 0.033,
            color: AppColors.grey2,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final bool isAction;
  final Color? iconColor;
  final Color? iconBg;
  final VoidCallback? onTap;

  const SectionTile({
    super.key,
    required this.icon,
    required this.title,
    this.selected = false,
    this.isAction = false,
    this.iconColor,
    this.iconBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final Color effectiveIconBg =
        iconBg ??
        (selected ? AppColors.blue7 : AppColors.white4);
    final Color effectiveIconColor =
        iconColor ??
        (selected ? AppColors.blue : AppColors.grey5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.01),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.045,
            vertical: w * 0.038,
          ),
          child: Row(
            children: [
              Container(
                width: w * 0.11,
                height: w * 0.11,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(w * 0.03),
                  boxShadow: isAction
                      ? [
                          BoxShadow(
                            color: effectiveIconColor.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(icon, color: effectiveIconColor, size: w * 0.055),
              ),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: isAction ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.blue6,
                  ),
                ),
              ),
              Container(
                width: w * 0.075,
                height: w * 0.075,
                decoration: BoxDecoration(
                  color: isAction
                      ? effectiveIconColor.withValues(alpha: 0.1)
                      : AppColors.white4,
                  borderRadius: BorderRadius.circular(w * 0.022),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isAction
                      ? effectiveIconColor
                      : AppColors.grey2,
                  size: w * 0.055,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
