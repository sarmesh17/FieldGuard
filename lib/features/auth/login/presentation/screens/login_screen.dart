import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../legal/legal_content.dart';
import '../../../../legal/presentation/providers/legal_version_provider.dart';
import '../../../../legal/presentation/widgets/legal_consent_checkbox.dart';
import '../providers/login_provider.dart';
import '../providers/login_state.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

// ─── Brand colours ─────────────────────────────────────────────────────────────
const _kDark = AppColors.green;
const _kPrimary = AppColors.green;
const _kMid = AppColors.gradientStart;
const _kLight = AppColors.gradientEnd;
const _kFocus = AppColors.green6;

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
  bool _agreedToTerms = false;

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

    // Warm up the legal version from the backend so it's ready by submit time.
    ref.read(legalVersionProvider);
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
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms & Conditions and Privacy Policy to continue',
          ),
        ),
      );
      return;
    }
    // Version comes from the backend (source of truth); fall back to the
    // bundled version if the fetch hasn't resolved yet.
    final termsVersion =
        ref.read(legalVersionProvider).asData?.value ?? kLegalLastUpdated;
    ref
        .read(loginNotifierProvider.notifier)
        .login(
          phone,
          password,
          termsAccepted: _agreedToTerms,
          termsVersion: termsVersion,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginNotifierProvider, (_, next) {
      if (next is LoginSuccess) context.go(AppRoutes.dashboard);
    });

    final loginState = ref.watch(loginNotifierProvider);
    final isLoading = loginState is LoginLoading;
    final errorMessage = loginState is LoginFailure ? loginState.message : null;
    final rateLimited = loginState is LoginFailure && loginState.rateLimited;

    final kbHeight = MediaQuery.of(context).viewInsets.bottom;
    final t = (kbHeight / 220.0).clamp(0.0, 1.0);

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        // Safe fallback for checking orientation standardly
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

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
                child: const _Orb(size: 240, opacity: 0.08),
              ),
              Positioned(
                top: 140,
                left: -90,
                child: const _Orb(size: 200, opacity: 0.06),
              ),
              Positioned(
                bottom: -60,
                left: -40,
                child: const _Orb(size: 180, opacity: 0.07),
              ),
              Positioned(
                bottom: 120,
                right: -55,
                child: const _Orb(size: 150, opacity: 0.05),
              ),

              // ── Main Content (Adaptive Form Implementation) ─────────────────
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, viewportConstraints) {
                    // A "short" screen can't fit the full-size logo, card and
                    // footer at once. Detect it so vertical spacing collapses
                    // instead of overlapping ("blender").
                    final isShort = viewportConstraints.maxHeight < 680;
                    // Flexible gaps above/below the card. They shrink to zero on
                    // short screens (scroll takes over) but breathe on tall ones.
                    final gap = isShort
                        ? SizeConfig.vScale(12)
                        : SizeConfig.heightPercent(3);

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: viewportConstraints.maxHeight,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            // Limit max width in landscape to avoid stretched UI
                            constraints: BoxConstraints(
                              maxWidth: isLandscape ? 480 : double.infinity,
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                // Remove side padding in landscape since it's already centered and constrained
                                left: isLandscape ? 0 : AppSpacing.md,
                                right: isLandscape ? 0 : AppSpacing.md,
                                top: SizeConfig.vScale(8),
                                bottom: kbHeight > 0
                                    ? kbHeight + 20
                                    : SizeConfig.vScale(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height:
                                        SizeConfig.vScale(8) +
                                        (SizeConfig.vScale(24) -
                                                SizeConfig.vScale(8)) *
                                            (1.0 - t),
                                  ),

                                  // ── Logo + Header ──────────────────────────
                                  ClipRect(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      heightFactor: 1.0 - t,
                                      child: Opacity(
                                        opacity: 1.0 - t,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ScaleTransition(
                                              scale: _logoScale,
                                              child: Container(
                                                width: SizeConfig.vScale(72),
                                                height: SizeConfig.vScale(72),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          AppColors.green5,
                                                          AppColors.green,
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                    width: 2.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _kDark.withValues(
                                                        alpha: 0.40,
                                                      ),
                                                      blurRadius: 24,
                                                      offset: const Offset(
                                                        0,
                                                        8,
                                                      ),
                                                    ),
                                                    BoxShadow(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.08,
                                                          ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        -2,
                                                        -2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.shield_outlined,
                                                  color: Colors.white,
                                                  size: SizeConfig.vScale(36),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: SizeConfig.vScale(16),
                                            ),
                                            FadeTransition(
                                              opacity: _headerFade,
                                              child: SlideTransition(
                                                position: _headerSlide,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                SizeConfig.scale(
                                                                  14,
                                                                ),
                                                            vertical:
                                                                SizeConfig.scale(
                                                                  5,
                                                                ),
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.14,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              SizeConfig.scale(
                                                                20,
                                                              ),
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.28,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .verified_user_outlined,
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.90,
                                                                ),
                                                            size:
                                                                SizeConfig.scale(
                                                                  12,
                                                                ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                SizeConfig.scale(
                                                                  6,
                                                                ),
                                                          ),
                                                          Text(
                                                            'SECURE ACCESS',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.90,
                                                                  ),
                                                              fontSize:
                                                                  SizeConfig.scaledFontSize(
                                                                    9,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              letterSpacing:
                                                                  1.5,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          SizeConfig.heightPercent(
                                                            1.2,
                                                          ),
                                                    ),
                                                    Text(
                                                      'Login Portal',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize:
                                                            SizeConfig.scaledFontSize(
                                                              28,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: -0.5,
                                                        height: 1.1,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          SizeConfig.heightPercent(
                                                            0.8,
                                                          ),
                                                    ),
                                                    Text(
                                                      'Enter your credentials to access your portal',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.65,
                                                            ),
                                                        fontSize:
                                                            SizeConfig.scaledFontSize(
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

                                  SizedBox(height: gap),

                                  // ── Form card ──────────────────────────────
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
                                        rateLimited: rateLimited,
                                        agreedToTerms: _agreedToTerms,
                                        onToggleTerms: (v) =>
                                            setState(() => _agreedToTerms = v),
                                        onTogglePassword: () => setState(
                                          () => _hidePassword = !_hidePassword,
                                        ),
                                        onSignIn: _onSignIn,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: gap),

                                  // ── Footer ─────────────────────────────────
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
                                                onTap: () => context.push(
                                                  AppRoutes.signup,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        SizeConfig.scale(20),
                                                    vertical: SizeConfig.scale(
                                                      11,
                                                    ),
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.13,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          SizeConfig.scale(14),
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .add_business_outlined,
                                                        size: SizeConfig.scale(
                                                          15,
                                                        ),
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.85,
                                                            ),
                                                      ),
                                                      SizedBox(
                                                        width: SizeConfig.scale(
                                                          8,
                                                        ),
                                                      ),
                                                      RichText(
                                                        text: TextSpan(
                                                          style: TextStyle(
                                                            fontSize:
                                                                SizeConfig.scaledFontSize(
                                                                  13,
                                                                ),
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.75,
                                                                ),
                                                          ),
                                                          children: const [
                                                            TextSpan(
                                                              text:
                                                                  "New here?  ",
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  'Register Your Company',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
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
                                                height: SizeConfig.scale(3),
                                              ),
                                              Text(
                                                'Access is granted by your organization admin only',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize:
                                                      SizeConfig.scaledFontSize(
                                                        9,
                                                      ),
                                                  color: Colors.white
                                                      .withValues(alpha: 0.32),
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    SizeConfig.heightPercent(3),
                                              ),
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
                        ),
                      ),
                    );
                  },
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
  final bool rateLimited;
  final bool agreedToTerms;
  final ValueChanged<bool> onToggleTerms;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;

  const _FormCard({
    required this.phoneController,
    required this.passwordController,
    required this.hidePassword,
    required this.isLoading,
    this.errorMessage,
    this.rateLimited = false,
    required this.agreedToTerms,
    required this.onToggleTerms,
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
                  hint: '9800000000',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
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
                          rateLimited
                              ? Icons.hourglass_top_rounded
                              : Icons.error_outline_rounded,
                          color: rateLimited
                              ? Colors.orange.shade800
                              : Colors.red.shade600,
                          size: SizeConfig.scale(14),
                        ),
                        SizedBox(width: SizeConfig.scale(6)),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: rateLimited
                                  ? Colors.orange.shade800
                                  : Colors.red.shade600,
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
                    onPressed: () => context.push(AppRoutes.forgotPassword),
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

                SizedBox(height: SizeConfig.scale(4)),

                // ── Consent checkbox ─────────────────────────────────────────
                LegalConsentCheckbox(
                  value: agreedToTerms,
                  onChanged: onToggleTerms,
                ),

                SizedBox(height: SizeConfig.scale(16)),

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
  final List<TextInputFormatter>? inputFormatters;

  const _ModernField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
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
          color: _focused ? _kFocus : AppColors.white2,
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
                        : [AppColors.grey15, AppColors.green6],
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
                  inputFormatters: widget.inputFormatters,
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
          color: _focused ? _kFocus : AppColors.white2,
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
                        : [AppColors.grey15, AppColors.green6],
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
