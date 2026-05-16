import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/router/app_routes.dart';
import '../providers/login_provider.dart';
import '../providers/login_state.dart';

// ─── Brand colours ─────────────────────────────────────────────────────────────
const _kDark = Color(0xFF1A4731);
const _kPrimary = Color(0xFF165C3D);
const _kMid = Color(0xFF2E6F4F);
const _kLight = Color(0xFF5FBF8F);
const _kFocus = Color(0xFFF0FAF5);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _bottomFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.45, curve: Curves.elasticOut),
    );

    final headerCurve = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.55, curve: Curves.easeOut),
    );
    _headerFade = headerCurve;
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(headerCurve);

    final cardCurve = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.32, 0.68, curve: Curves.easeOut),
    );
    _cardFade = cardCurve;
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(cardCurve);

    _bottomFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 0.90, curve: Curves.easeOut),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number and password are required')),
      );
      return;
    }
    ref.read(loginNotifierProvider.notifier).login(phone, password);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginNotifierProvider, (_, next) {
      if (next is LoginSuccess) context.go(AppRoutes.dashboard);
    });

    final loginState = ref.watch(loginNotifierProvider);
    final isLoading = loginState is LoginLoading;
    final errorMessage = loginState is LoginFailure ? loginState.message : null;

    // collapseProgress: 0 = keyboard hidden, 1 = fully collapsed.
    // Driven directly by keyboard inset so layout syncs frame-by-frame
    // with the keyboard animation — no competing timers.
    final kbHeight = MediaQuery.of(context).viewInsets.bottom;
    final t = (kbHeight / 220.0).clamp(0.0, 1.0);

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // ── Gradient background ─────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kDark, _kMid, _kLight],
                    stops: [0.0, 0.50, 1.0],
                  ),
                ),
              ),

              // ── Decorative orbs ─────────────────────────────────────────────
              Positioned(
                top: -80,
                right: -80,
                child: _Orb(size: 240, opacity: 0.08),
              ),
              Positioned(
                top: 140,
                left: -90,
                child: _Orb(size: 200, opacity: 0.06),
              ),
              Positioned(
                bottom: -60,
                left: -40,
                child: _Orb(size: 180, opacity: 0.07),
              ),
              Positioned(
                bottom: 120,
                right: -55,
                child: _Orb(size: 150, opacity: 0.05),
              ),

              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: kbHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top spacing shrinks with keyboard
                      SizedBox(
                        height:
                            8.0 +
                            (SizeConfig.heightPercent(4) - 8.0) * (1.0 - t),
                      ),

                      // ── Logo + header collapse in sync with keyboard ─────────
                      // ClipRect+Align(heightFactor) is the most efficient way
                      // to animate height — no AnimationController needed.
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 1.0 - t,
                          child: Opacity(
                            opacity: 1.0 - t,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo
                                ScaleTransition(
                                  scale: _logoScale,
                                  child: Container(
                                    width: SizeConfig.scale(72),
                                    height: SizeConfig.scale(72),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2E7D52),
                                          Color(0xFF1A4731),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kDark.withValues(alpha: 0.40),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(-2, -2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      color: Colors.white,
                                      size: SizeConfig.scale(36),
                                    ),
                                  ),
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                // Badge + title + subtitle
                                FadeTransition(
                                  opacity: _headerFade,
                                  child: SlideTransition(
                                    position: _headerSlide,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: SizeConfig.scale(14),
                                            vertical: SizeConfig.scale(5),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              SizeConfig.scale(20),
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.28,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified_user_outlined,
                                                color: Colors.white.withValues(
                                                  alpha: 0.90,
                                                ),
                                                size: SizeConfig.scale(12),
                                              ),
                                              SizedBox(
                                                width: SizeConfig.scale(6),
                                              ),
                                              Text(
                                                'SECURE ACCESS',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.90),
                                                  fontSize:
                                                      SizeConfig.scaledFontSize(
                                                        9,
                                                      ),
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(1.2),
                                        ),

                                        Text(
                                          'Login Portal',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: SizeConfig.scaledFontSize(
                                              28,
                                            ),
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                            height: 1.1,
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.8),
                                        ),

                                        Text(
                                          'Enter your credentials to access your portal',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.65,
                                            ),
                                            fontSize: SizeConfig.scaledFontSize(
                                              12,
                                            ),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ── Form card ───────────────────────────────────────────
                      FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: _FormCard(
                            phoneController: _phoneController,
                            passwordController: _passwordController,
                            hidePassword: _hidePassword,
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            onTogglePassword: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            onSignIn: _onSignIn,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ── Footer collapses in sync with keyboard ──────────────
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 1.0 - t,
                          child: Opacity(
                            opacity: 1.0 - t,
                            child: FadeTransition(
                              opacity: _bottomFade,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => context.push(AppRoutes.signup),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: SizeConfig.scale(20),
                                        vertical: SizeConfig.scale(11),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.13,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          SizeConfig.scale(14),
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_business_outlined,
                                            size: SizeConfig.scale(15),
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                          SizedBox(width: SizeConfig.scale(8)),
                                          RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize:
                                                    SizeConfig.scaledFontSize(
                                                      13,
                                                    ),
                                                color: Colors.white.withValues(
                                                  alpha: 0.75,
                                                ),
                                              ),
                                              children: const [
                                                TextSpan(text: "New here?  "),
                                                TextSpan(
                                                  text: 'Register Your Company',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: SizeConfig.heightPercent(1.5),
                                  ),

                                  Text(
                                    'FIELDGUARD PORTAL V1.0',
                                    style: TextStyle(
                                      fontSize: SizeConfig.scaledFontSize(8),
                                      letterSpacing: 1.5,
                                      color: Colors.white.withValues(
                                        alpha: 0.40,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.scale(3)),
                                  Text(
                                    'Access is granted by your organization admin only',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: SizeConfig.scaledFontSize(9),
                                      color: Colors.white.withValues(
                                        alpha: 0.32,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.heightPercent(3)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern form card
// ─────────────────────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool hidePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;

  const _FormCard({
    required this.phoneController,
    required this.passwordController,
    required this.hidePassword,
    required this.isLoading,
    this.errorMessage,
    required this.onTogglePassword,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(28)),
        boxShadow: [
          BoxShadow(
            color: _kDark.withValues(alpha: 0.28),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient accent stripe ────────────────────────────────────────
          Container(
            height: SizeConfig.scale(3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_kDark, _kMid, _kLight]),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              SizeConfig.scale(20),
              AppSpacing.md,
              SizeConfig.scale(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Modern card header ───────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tag pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.scale(10),
                        vertical: SizeConfig.scale(4),
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kMid, _kDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          SizeConfig.scale(20),
                        ),
                      ),
                      child: Text(
                        'SIGN IN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.scaledFontSize(8),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.scale(10)),

                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(22),
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),

                SizedBox(height: SizeConfig.scale(4)),

                Text(
                  'Access your FieldGuard dashboard',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(12),
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: SizeConfig.scale(24)),

                // ── Phone field ──────────────────────────────────────────────
                _ModernField(
                  controller: phoneController,
                  icon: Icons.phone_android_rounded,
                  hint: '+91  98000 00000',
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: SizeConfig.scale(14)),

                // ── Password field ───────────────────────────────────────────
                _ModernPasswordField(
                  controller: passwordController,
                  hide: hidePassword,
                  onToggle: onTogglePassword,
                ),

                // ── Error message (inline) ───────────────────────────────────
                if (errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: SizeConfig.scale(8),
                      left: SizeConfig.scale(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade600,
                          size: SizeConfig.scale(14),
                        ),
                        SizedBox(width: SizeConfig.scale(6)),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: SizeConfig.scaledFontSize(11),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Forgot password ──────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.scale(6),
                        horizontal: SizeConfig.scale(4),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: _kPrimary,
                        fontSize: SizeConfig.scaledFontSize(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: SizeConfig.scale(12)),

                // ── Sign in button ───────────────────────────────────────────
                _SignInButton(isLoading: isLoading, onPressed: onSignIn),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern pill-shaped field (phone / generic)
// ─────────────────────────────────────────────────────────────────────────────
class _ModernField extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType keyboardType;

  const _ModernField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_ModernField> createState() => _ModernFieldState();
}

class _ModernFieldState extends State<_ModernField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: SizeConfig.scale(56),
        decoration: BoxDecoration(
          color: _focused ? _kFocus : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
          border: Border.all(
            color: _focused ? _kMid : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _focused
                  ? _kPrimary.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: _focused ? 16 : 6,
              offset: Offset(0, _focused ? 4 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(14)),
          child: Row(
            children: [
              // Animated icon badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: SizeConfig.scale(34),
                height: SizeConfig.scale(34),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _focused
                        ? [_kMid, _kDark]
                        : [const Color(0xFFE4EDE8), const Color(0xFFD8E7DE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: _focused
                      ? [
                          BoxShadow(
                            color: _kMid.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  widget.icon,
                  color: _focused
                      ? Colors.white
                      : _kMid.withValues(alpha: 0.70),
                  size: SizeConfig.scale(16),
                ),
              ),

              SizedBox(width: SizeConfig.scale(12)),

              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: SizeConfig.scaledFontSize(14),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(14),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern password field
// ─────────────────────────────────────────────────────────────────────────────
class _ModernPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final bool hide;
  final VoidCallback onToggle;

  const _ModernPasswordField({
    required this.controller,
    required this.hide,
    required this.onToggle,
  });

  @override
  State<_ModernPasswordField> createState() => _ModernPasswordFieldState();
}

class _ModernPasswordFieldState extends State<_ModernPasswordField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: SizeConfig.scale(56),
        decoration: BoxDecoration(
          color: _focused ? _kFocus : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
          border: Border.all(
            color: _focused ? _kMid : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _focused
                  ? _kPrimary.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: _focused ? 16 : 6,
              offset: Offset(0, _focused ? 4 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.scale(14),
            right: SizeConfig.scale(4),
          ),
          child: Row(
            children: [
              // Animated icon badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: SizeConfig.scale(34),
                height: SizeConfig.scale(34),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _focused
                        ? [_kMid, _kDark]
                        : [const Color(0xFFE4EDE8), const Color(0xFFD8E7DE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: _focused
                      ? [
                          BoxShadow(
                            color: _kMid.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: _focused
                      ? Colors.white
                      : _kMid.withValues(alpha: 0.70),
                  size: SizeConfig.scale(16),
                ),
              ),

              SizedBox(width: SizeConfig.scale(12)),

              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: widget.hide,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '••••••••',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: SizeConfig.scaledFontSize(14),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(14),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),

              // Toggle visibility
              GestureDetector(
                onTap: widget.onToggle,
                child: Container(
                  width: SizeConfig.scale(36),
                  height: SizeConfig.scale(36),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.hide
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: SizeConfig.scale(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-in button with press-scale animation
// ─────────────────────────────────────────────────────────────────────────────
class _SignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.96,
      upperBound: 1.00,
      value: 1.00,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) => _press.forward(),
      onTapCancel: () => _press.forward(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: Container(
          width: double.infinity,
          height: SizeConfig.scale(54),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kDark, _kMid],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _kDark.withValues(alpha: 0.20),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    height: SizeConfig.scale(22),
                    width: SizeConfig.scale(22),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.scaledFontSize(16),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background orb
// ─────────────────────────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double size;
  final double opacity;
  const _Orb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}
