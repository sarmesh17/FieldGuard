import 'package:fieldguard/features/admin_profile/section_card.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/employee/presentation/screens/create_employee_screen.dart';
import 'package:fieldguard/features/manager/presentation/screens/create_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final avatarSize = w * 0.28;
    final headerHeight = h * 0.30;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header + Avatar overlap
            Stack(
              clipBehavior: Clip.none,
              children: [
                FadeTransition(
                  opacity: _headerFade,
                  child: _buildGradientHeader(w, h, headerHeight),
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
                        child: _buildAvatar(avatarSize, w),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: avatarSize / 2 + w * 0.05),
            // Name, email, badge
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildProfileInfo(w),
              ),
            ),
            SizedBox(height: h * 0.025),
            // Stats card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildStatsCard(w, h),
              ),
            ),
            SizedBox(height: h * 0.022),
            // Admin Tools
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
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
                        iconColor: const Color(0xff0E5A3B),
                        iconBg: const Color(0xffDCF5E4),
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
                      SectionTile(
                        icon: Icons.supervisor_account_rounded,
                        title: 'Create New Manager',
                        iconColor: const Color(0xff6558FF),
                        iconBg: const Color(0xffEEE9FF),
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
                      const SectionTile(
                        icon: Icons.settings_outlined,
                        title: 'System Settings',
                        selected: true,
                      ),
                      const SectionTile(
                        icon: Icons.receipt_long_outlined,
                        title: 'Audit Logs',
                      ),
                      const SectionTile(
                        icon: Icons.download_outlined,
                        title: 'Backup & Export',
                      ),
                      const SectionTile(
                        icon: Icons.gavel_outlined,
                        title: 'Fraud Rule Configuration',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: h * 0.018),
            // Account
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const SectionCard(
                    title: 'ACCOUNT',
                    items: [
                      SectionTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                      ),
                      SectionTile(
                        icon: Icons.shield_outlined,
                        title: 'Security & Passwords',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: h * 0.035),
            // Sign Out
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSignOutButton(w, h),
              ),
            ),
            SizedBox(height: h * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(double w, double h, double headerHeight) {
    return ClipPath(
      clipper: _ProfileHeaderClipper(),
      child: Container(
        height: headerHeight,
        width: w,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff072A1C),
              Color(0xff0E5A3B),
              Color(0xff1D7A51),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -h * 0.07,
              right: -w * 0.12,
              child: _decorCircle(w * 0.55, 0.07),
            ),
            Positioned(
              top: h * 0.04,
              right: w * 0.1,
              child: _decorCircle(w * 0.18, 0.05),
            ),
            Positioned(
              top: h * 0.02,
              left: -w * 0.07,
              child: _decorCircle(w * 0.38, 0.05),
            ),
            Positioned(
              bottom: h * 0.14,
              left: w * 0.25,
              child: _decorCircle(w * 0.1, 0.04),
            ),
            // Top bar
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04,
                  vertical: w * 0.01,
                ),
                child: Row(
                  children: [
                    Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    _headerIconButton(Icons.notifications_none_rounded, w),
                    SizedBox(width: w * 0.02),
                    _headerIconButton(Icons.more_horiz_rounded, w),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, double w) {
    return Container(
      width: w * 0.1,
      height: w * 0.1,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      child: Icon(icon, color: Colors.white, size: w * 0.055),
    );
  }

  Widget _buildAvatar(double avatarSize, double w) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0E5A3B).withValues(alpha: 0.28),
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
            child: Image.network(
              'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=800&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: w * 0.09,
            height: w * 0.09,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xff0E5A3B), Color(0xff1D7A51)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0E5A3B).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: w * 0.045,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(double w) {
    return Column(
      children: [
        Text(
          'Alex Sterling',
          style: TextStyle(
            fontSize: w * 0.068,
            fontWeight: FontWeight.w800,
            color: const Color(0xff111827),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: w * 0.018),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alternate_email_rounded,
              size: w * 0.038,
              color: const Color(0xff6B7280),
            ),
            SizedBox(width: w * 0.012),
            Text(
              'alex.s@fieldops.inc',
              style: TextStyle(
                fontSize: w * 0.037,
                color: const Color(0xff6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        SizedBox(height: w * 0.04),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.055,
            vertical: w * 0.022,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff6558FF), Color(0xff9B4EFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(w * 0.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff6558FF).withValues(alpha: 0.38),
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
                'System Admin',
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

  Widget _buildStatsCard(double w, double h) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: h * 0.024),
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
      child: const Row(
        children: [
          Expanded(
            child: AnimatedStatItem(value: '4', title: 'Managers', delay: 300),
          ),
          _StatsVerticalDivider(),
          Expanded(
            child: AnimatedStatItem(value: '24', title: 'Reps', delay: 500),
          ),
          _StatsVerticalDivider(),
          Expanded(
            child: AnimatedStatItem(value: '186', title: 'Shops', delay: 700),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(double w, double h) {
    return GestureDetector(
      onTap: () async {
        // Show confirmation dialog
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xffE53935),
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
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
        padding: EdgeInsets.symmetric(vertical: h * 0.019),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: const Color(0xffFFCDD2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffE53935).withValues(alpha: 0.08),
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
              color: const Color(0xffE53935),
              size: w * 0.055,
            ),
            SizedBox(width: w * 0.025),
            Text(
              'Sign Out',
              style: TextStyle(
                color: const Color(0xffE53935),
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
      color: const Color(0xffE5E7EB),
    );
  }
}

class AnimatedStatItem extends StatefulWidget {
  final String value;
  final String title;
  final int delay;

  const AnimatedStatItem({
    super.key,
    required this.value,
    required this.title,
    this.delay = 0,
  });

  @override
  State<AnimatedStatItem> createState() => _AnimatedStatItemState();
}

class _AnimatedStatItemState extends State<AnimatedStatItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: double.parse(widget.value),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              _animation.value.toInt().toString(),
              style: TextStyle(
                fontSize: w * 0.072,
                fontWeight: FontWeight.w800,
                color: const Color(0xff0E5A3B),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: w * 0.012),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: w * 0.033,
                color: const Color(0xff9CA3AF),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        );
      },
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

    final Color effectiveIconBg = iconBg ??
        (selected ? const Color(0xffEEE9FF) : const Color(0xffF3F4F6));
    final Color effectiveIconColor = iconColor ??
        (selected ? const Color(0xff635BFF) : const Color(0xff6B7280));

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
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: w * 0.055,
                ),
              ),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: isAction ? FontWeight.w600 : FontWeight.w500,
                    color: const Color(0xff1F2937),
                  ),
                ),
              ),
              Container(
                width: w * 0.075,
                height: w * 0.075,
                decoration: BoxDecoration(
                  color: isAction
                      ? effectiveIconColor.withValues(alpha: 0.1)
                      : const Color(0xffF3F4F6),
                  borderRadius: BorderRadius.circular(w * 0.022),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isAction ? effectiveIconColor : const Color(0xff9CA3AF),
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
