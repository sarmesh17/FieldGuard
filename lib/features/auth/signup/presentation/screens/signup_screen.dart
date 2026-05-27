import 'package:file_picker/file_picker.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/router/app_routes.dart';
import 'package:fieldguard/features/auth/signup/presentation/providers/signup_provider.dart';
import 'package:fieldguard/features/auth/signup/presentation/providers/signup_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─── Brand colours ─────────────────────────────────────────────────────────────
const _kDark = Color(0xFF1A4731);
const _kPrimary = Color(0xFF165C3D);
const _kMid = Color(0xFF2E6F4F);
const _kLight = Color(0xFF5FBF8F);
const _kFieldFocus = Color(0xFFF0FAF5);

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  // ── Form controllers ───────────────────────────────────────────────────────
  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _panCardController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _citizenshipImagePath;
  String? _registrationDocPath;

  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final List<Animation<double>> _itemFades;
  late final List<Animation<Offset>> _itemSlides;

  static const _itemCount = 8;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.42, curve: Curves.elasticOut),
    );

    final headerCurve = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.52, curve: Curves.easeOut),
    );
    _headerFade = headerCurve;
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(headerCurve);

    final cardCurve = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
    );
    _cardFade = cardCurve;
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(cardCurve);

    _itemFades = List.generate(_itemCount, (i) {
      final start = 0.42 + i * 0.055;
      final end = (start + 0.28).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });
    _itemSlides = List.generate(_itemCount, (i) {
      final start = 0.42 + i * 0.055;
      final end = (start + 0.28).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.55),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _panCardController.dispose();
    _adminNameController.dispose();
    _phoneNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation & submit ────────────────────────────────────────────────────
  void _onSignUp() {
    final companyName = _companyNameController.text.trim();
    final companyEmail = _companyEmailController.text.trim();
    final companyPhone = _companyPhoneController.text.trim();
    final panCard = _panCardController.text.trim();
    final adminName = _adminNameController.text.trim();
    final phone = _phoneNoController.text.trim();
    final password = _passwordController.text;

    if (companyName.isEmpty ||
        companyEmail.isEmpty ||
        companyPhone.isEmpty ||
        panCard.isEmpty ||
        adminName.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      _snack('Please fill in all required fields');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(companyEmail)) {
      _snack('Please enter a valid company email');
      return;
    }
    if (_citizenshipImagePath == null || _registrationDocPath == null) {
      _snack('Please upload both required documents');
      return;
    }

    ref
        .read(signupNotifierProvider.notifier)
        .register(
          companyName: companyName,
          companyEmail: companyEmail,
          companyPhone: companyPhone,
          panNumber: panCard,
          adminName: adminName,
          phoneNumber: phone,
          password: password,
          citizenshipImagePath: _citizenshipImagePath!,
          registrationDocPath: _registrationDocPath!,
        );
  }

  void _snack(String msg, {Color? bg}) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));

  Widget _item(int i, Widget child) => FadeTransition(
    opacity: _itemFades[i],
    child: SlideTransition(position: _itemSlides[i], child: child),
  );

  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    ref.listen<SignupState>(signupNotifierProvider, (prev, next) {
      // Navigate ONLY on the false→true transition. Without the prev check
      // this fires on every state change (e.g. toggling password visibility)
      // and re-routes a user who has already seen the success screen.
      final justSucceeded = next.isSuccess && !(prev?.isSuccess ?? false);
      if (justSucceeded) {
        context.go(AppRoutes.registrationSuccess);
      } else if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        _snack(next.errorMessage!, bg: Colors.red.shade700);
      }
    });

    final signupState = ref.watch(signupNotifierProvider);

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          body: Stack(
            children: [
              // ── Gradient background ─────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kDark, _kMid, _kLight],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),

              // ── Decorative circles ──────────────────────────────────────────
              Positioned(
                top: -70,
                right: -70,
                child: _BgCircle(size: 240, opacity: 0.09),
              ),
              Positioned(
                top: 140,
                left: -90,
                child: _BgCircle(size: 210, opacity: 0.06),
              ),
              Positioned(
                bottom: -50,
                right: -50,
                child: _BgCircle(size: 200, opacity: 0.07),
              ),

              // ── Scrollable content ──────────────────────────────────────────
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenType == ScreenType.large
                          ? 520
                          : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: SizeConfig.heightPercent(4)),

                        // ── Logo ──────────────────────────────────────────────
                        ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            width: SizeConfig.scale(72),
                            height: SizeConfig.scale(72),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              color: Colors.white,
                              size: SizeConfig.scale(38),
                            ),
                          ),
                        ),

                        SizedBox(height: SizeConfig.heightPercent(2.5)),

                        // ── Title + subtitle ──────────────────────────────────
                        FadeTransition(
                          opacity: _headerFade,
                          child: SlideTransition(
                            position: _headerSlide,
                            child: Column(
                              children: [
                                Text(
                                  'Register Your Company',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: SizeConfig.scaledFontSize(24),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: SizeConfig.heightPercent(1)),
                                Text(
                                  'Complete the form below to get started',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: SizeConfig.scaledFontSize(13),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: SizeConfig.heightPercent(4)),

                        // ── Form card ─────────────────────────────────────────
                        FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: Container(
                              width: double.infinity,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  SizeConfig.scale(28),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kDark.withValues(alpha: 0.30),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Card header banner ──────────────────────
                                  _FormCardHeader(),

                                  // ── Form body ───────────────────────────────
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      AppSpacing.md,
                                      AppSpacing.md,
                                      AppSpacing.md,
                                      AppSpacing.md,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ── ① Company ─────────────────────────
                                        _item(
                                          0,
                                          const _StepHeader(
                                            step: 1,
                                            label: 'Company Information',
                                            subtitle:
                                                'Enter your business details',
                                            icon: Icons.business_outlined,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(2),
                                        ),

                                        _item(
                                          0,
                                          const _FieldLabel(
                                            'Company Name',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.7),
                                        ),
                                        _item(
                                          0,
                                          _InputField(
                                            controller: _companyNameController,
                                            icon: Icons.corporate_fare_outlined,
                                            hint: 'e.g. FieldGuard Pvt. Ltd.',
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(2),
                                        ),
                                        _item(
                                          1,
                                          const _FieldLabel(
                                            'Company Email',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.7),
                                        ),
                                        _item(
                                          1,
                                          _InputField(
                                            controller: _companyEmailController,
                                            icon: Icons.alternate_email_rounded,
                                            hint: 'contact@acme.com',
                                            keyboardType:
                                                TextInputType.emailAddress,
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(2),
                                        ),
                                        _item(
                                          1,
                                          const _FieldLabel(
                                            'Company Phone',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.7),
                                        ),
                                        _item(
                                          1,
                                          _InputField(
                                            controller: _companyPhoneController,
                                            icon: Icons.call_outlined,
                                            hint: '9800000000',
                                            keyboardType: TextInputType.phone,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                10,
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(2),
                                        ),
                                        _item(
                                          1,
                                          const _FieldLabel(
                                            'PAN Card Number',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.7),
                                        ),
                                        _item(
                                          1,
                                          _InputField(
                                            controller: _panCardController,
                                            icon: Icons.contact_page_outlined,
                                            hint: 'ABCDE1234N',
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(3.5),
                                        ),
                                        _item(
                                          2,
                                          const _SectionConnector(
                                            step: 1,
                                            nextStep: 2,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(3.5),
                                        ),

                                        // ── ② Admin ───────────────────────────
                                        _item(
                                          2,
                                          const _StepHeader(
                                            step: 2,
                                            label: 'Admin Details',
                                            subtitle:
                                                'Primary account administrator',
                                            icon: Icons.person_outline_rounded,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(2),
                                        ),

                                        _item(
                                          2,
                                          const _FieldLabel(
                                            'Admin Name',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.7),
                                        ),
                                        _item(
                                          2,
                                          _InputField(
                                            controller: _adminNameController,
                                            icon: Icons.badge_outlined,
                                            hint: 'John Doe',
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(2),
                                        ),
                                        _item(
                                          3,
                                          const _FieldLabel(
                                            'Mobile Number',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.7),
                                        ),
                                        _item(
                                          3,
                                          _PhoneField(
                                            controller: _phoneNoController,
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(2),
                                        ),
                                        _item(
                                          4,
                                          const _FieldLabel(
                                            'Password',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.7),
                                        ),
                                        _item(
                                          4,
                                          _SignupPasswordField(
                                            controller: _passwordController,
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(3.5),
                                        ),
                                        _item(
                                          5,
                                          const _SectionConnector(
                                            step: 2,
                                            nextStep: 3,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(3.5),
                                        ),

                                        // ── ③ Documents ───────────────────────
                                        _item(
                                          5,
                                          const _StepHeader(
                                            step: 3,
                                            label: 'Verification Documents',
                                            subtitle:
                                                'Required for account approval',
                                            icon: Icons.folder_copy_outlined,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(2),
                                        ),

                                        _item(
                                          5,
                                          const _FieldLabel(
                                            'Citizenship Proof',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.7),
                                        ),
                                        _item(
                                          5,
                                          _DocField(
                                            allowedExtensions: const [
                                              'jpg',
                                              'jpeg',
                                              'png',
                                            ],
                                            formatHint: 'JPG or PNG image',
                                            onFileSelected: (path) => setState(
                                              () =>
                                                  _citizenshipImagePath = path,
                                            ),
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(2),
                                        ),
                                        _item(
                                          6,
                                          const _FieldLabel(
                                            'Registration Document',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(0.7),
                                        ),
                                        _item(
                                          6,
                                          _DocField(
                                            allowedExtensions: const [
                                              'pdf',
                                              'jpg',
                                              'jpeg',
                                              'png',
                                            ],
                                            formatHint: 'PDF, JPG or PNG',
                                            onFileSelected: (path) => setState(
                                              () => _registrationDocPath = path,
                                            ),
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(4),
                                        ),

                                        // ── Submit ─────────────────────────────
                                        if ((signupState.progress?.isStarted ??
                                                false) &&
                                            !signupState.isLoading) ...[
                                          _item(
                                            7,
                                            const _ResumeNotice(),
                                          ),
                                          SizedBox(
                                            height:
                                                SizeConfig.heightPercent(1.5),
                                          ),
                                        ],
                                        _item(
                                          7,
                                          _SubmitButton(
                                            isLoading: signupState.isLoading,
                                            statusMessage:
                                                signupState.statusMessage,
                                            label:
                                                (signupState
                                                            .progress
                                                            ?.isStarted ??
                                                        false)
                                                    ? 'Complete Registration'
                                                    : 'Register Company',
                                            onPressed: _onSignUp,
                                          ),
                                        ),

                                        SizedBox(
                                          height: SizeConfig.heightPercent(2.5),
                                        ),
                                        _item(
                                          7,
                                          Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.lock_outline,
                                                  size: SizeConfig.scale(13),
                                                  color: Colors.grey.shade400,
                                                ),
                                                SizedBox(
                                                  width: SizeConfig.scale(5),
                                                ),
                                                Text(
                                                  'SECURE END-TO-END ENCRYPTION',
                                                  style: TextStyle(
                                                    fontSize:
                                                        SizeConfig.scaledFontSize(
                                                          8,
                                                        ),
                                                    letterSpacing: 1.2,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: SizeConfig.heightPercent(4)),

                        // ── Already have account ──────────────────────────────
                        FadeTransition(
                          opacity: _itemFades[7],
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(13),
                                  color: Colors.white.withValues(alpha: 0.80),
                                ),
                                children: const [
                                  TextSpan(text: 'Already have an account?  '),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: SizeConfig.heightPercent(5)),
                      ],
                    ),
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
// Background circle
// ─────────────────────────────────────────────────────────────────────────────
class _BgCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _BgCircle({required this.size, required this.opacity});

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

// ─────────────────────────────────────────────────────────────────────────────
// Form card header banner
// ─────────────────────────────────────────────────────────────────────────────
class _FormCardHeader extends StatelessWidget {
  const _FormCardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.scale(20),
        vertical: SizeConfig.scale(18),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kDark, _kMid],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.scale(8)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(SizeConfig.scale(10)),
            ),
            child: Icon(
              Icons.app_registration_rounded,
              color: Colors.white,
              size: SizeConfig.scale(18),
            ),
          ),
          SizedBox(width: SizeConfig.scale(12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registration Form',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeConfig.scaledFontSize(14),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: SizeConfig.scale(2)),
              Text(
                'Fill all 3 sections to complete',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: SizeConfig.scaledFontSize(11),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Step pills
          Row(
            children: List.generate(3, (i) {
              return Container(
                width: SizeConfig.scale(8),
                height: SizeConfig.scale(8),
                margin: EdgeInsets.only(left: SizeConfig.scale(4)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: i == 0 ? 1.0 : 0.35),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numbered step header
// ─────────────────────────────────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final int step;
  final String label;
  final String subtitle;
  final IconData icon;
  const _StepHeader({
    required this.step,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Step number badge
            Container(
              width: SizeConfig.scale(34),
              height: SizeConfig.scale(34),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kDark, _kMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: SizeConfig.scaledFontSize(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: SizeConfig.scale(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(14),
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(11),
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              color: _kPrimary.withValues(alpha: 0.12),
              size: SizeConfig.scale(34),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.scale(10)),
        // Gradient underline
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kMid,
                _kLight.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section connector between steps
// ─────────────────────────────────────────────────────────────────────────────
class _SectionConnector extends StatelessWidget {
  final int step;
  final int nextStep;
  const _SectionConnector({required this.step, required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.grey.shade200],
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: SizeConfig.scale(12)),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.scale(10),
            vertical: SizeConfig.scale(5),
          ),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
          ),
          child: Text(
            'Step $step of 3 complete',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(10),
              color: _kPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade200, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field label
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(10),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Colors.grey.shade600,
          ),
        ),
        if (required) ...[
          SizedBox(width: SizeConfig.scale(3)),
          Text(
            '*',
            style: TextStyle(
              color: Colors.red.shade400,
              fontSize: SizeConfig.scaledFontSize(12),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field shell — focus-aware border + tint + left accent
// Accepts the same FocusNode used by the TextField inside so there is
// only ONE node in the focus tree (no extra Focus wrapper that can
// intercept text input and break EditableText rendering).
// ─────────────────────────────────────────────────────────────────────────────
class _FieldShell extends StatefulWidget {
  final Widget child;
  final FocusNode focusNode;
  const _FieldShell({required this.child, required this.focusNode});

  @override
  State<_FieldShell> createState() => _FieldShellState();
}

class _FieldShellState extends State<_FieldShell> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_FieldShell old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _focused ? _kFieldFocus : Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        border: Border.all(
          color: _focused ? _kMid : Colors.grey.shade300,
          width: _focused ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? _kPrimary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: _focused ? 16 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(14)),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic text input
// ─────────────────────────────────────────────────────────────────────────────
class _InputField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  ConsumerState<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends ConsumerState<_InputField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      focusNode: _focusNode,
      child: Row(
        children: [
          Icon(
            widget.icon,
            color: _kMid.withValues(alpha: 0.7),
            size: SizeConfig.scale(20),
          ),
          SizedBox(width: SizeConfig.scale(12)),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: SizeConfig.scaledFontSize(14),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: SizeConfig.scale(15),
                ),
              ),
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(14),
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password field with strength meter
// ─────────────────────────────────────────────────────────────────────────────
class _SignupPasswordField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  const _SignupPasswordField({required this.controller});

  @override
  ConsumerState<_SignupPasswordField> createState() =>
      _SignupPasswordFieldState();
}

class _SignupPasswordFieldState extends ConsumerState<_SignupPasswordField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hide = ref.watch(
      signupNotifierProvider.select((s) => s.hidePassword),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldShell(
          focusNode: _focusNode,
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: _kMid.withValues(alpha: 0.7),
                size: SizeConfig.scale(20),
              ),
              SizedBox(width: SizeConfig.scale(12)),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: hide,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '••••••••',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: SizeConfig.scaledFontSize(14),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: SizeConfig.scale(15),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(14),
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => ref
                    .read(signupNotifierProvider.notifier)
                    .togglePasswordVisibility(),
                icon: Icon(
                  hide
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: SizeConfig.scale(20),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.scale(8)),
        ValueListenableBuilder(
          valueListenable: widget.controller,
          builder: (context, value, _) =>
              _PasswordStrengthBar(password: value.text),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password strength bar
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int get _score {
    if (password.isEmpty) return 0;
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) s++;
    return s;
  }

  Color get _color {
    switch (_score) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.amber.shade600;
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String get _label {
    switch (_score) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: SizeConfig.scale(4),
                margin: EdgeInsets.only(right: i < 3 ? SizeConfig.scale(4) : 0),
                decoration: BoxDecoration(
                  color: i < _score ? _color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: SizeConfig.scale(4)),
        Text(
          'Strength: $_label',
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(10),
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone field
// ─────────────────────────────────────────────────────────────────────────────
class _PhoneField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  ConsumerState<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends ConsumerState<_PhoneField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedKey = ref.watch(
      signupNotifierProvider.select((s) => s.selectedKey),
    );
    final notifier = ref.read(signupNotifierProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Country picker
        Container(
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.scale(8),
            horizontal: SizeConfig.scale(10),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              borderRadius: BorderRadius.circular(14),
              value: selectedKey,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                size: SizeConfig.scale(20),
                color: Colors.grey.shade600,
              ),
              onChanged: (v) {
                if (v != null) notifier.setSelectedCountry(v);
              },
              items: notifier.images.entries
                  .map<DropdownMenuItem<String>>(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: SizeConfig.scale(12),
                            backgroundImage: NetworkImage(e.value),
                          ),
                          SizedBox(width: SizeConfig.scale(6)),
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: SizeConfig.scaledFontSize(13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),

        SizedBox(width: SizeConfig.scale(10)),

        // Number input
        Expanded(
          child: _FieldShell(
            focusNode: _focusNode,
            child: Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: _kMid.withValues(alpha: 0.7),
                  size: SizeConfig.scale(20),
                ),
                SizedBox(width: SizeConfig.scale(10)),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '9800000000',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: SizeConfig.scaledFontSize(14),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: SizeConfig.scale(15),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(14),
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document upload tile
// ─────────────────────────────────────────────────────────────────────────────
class _DocField extends StatefulWidget {
  final void Function(String? path) onFileSelected;
  final List<String> allowedExtensions;
  final String formatHint;
  const _DocField({
    required this.onFileSelected,
    required this.allowedExtensions,
    required this.formatHint,
  });

  @override
  State<_DocField> createState() => _DocFieldState();
}

class _DocFieldState extends State<_DocField> {
  String? _fileName;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
    );
    if (result != null) {
      setState(() => _fileName = result.files.single.name);
      widget.onFileSelected(result.files.single.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploaded = _fileName != null;

    return GestureDetector(
      onTap: _pick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: EdgeInsets.all(SizeConfig.scale(14)),
        decoration: BoxDecoration(
          color: uploaded ? _kFieldFocus : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
          border: Border.all(
            color: uploaded ? _kMid : Colors.grey.shade300,
            width: uploaded ? 1.5 : 1.0,
          ),
          boxShadow: uploaded
              ? [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: SizeConfig.scale(46),
              height: SizeConfig.scale(46),
              decoration: BoxDecoration(
                color: uploaded
                    ? _kPrimary.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
              ),
              child: Icon(
                uploaded
                    ? Icons.check_circle_outline_rounded
                    : Icons.upload_file_outlined,
                color: uploaded ? _kPrimary : Colors.grey.shade500,
                size: SizeConfig.scale(24),
              ),
            ),

            SizedBox(width: SizeConfig.scale(12)),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(13),
                      fontWeight: uploaded ? FontWeight.w600 : FontWeight.w500,
                      color: uploaded ? _kPrimary : Colors.grey.shade600,
                    ),
                    child: Text(
                      uploaded ? _fileName! : 'Tap to upload document',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(3)),
                  Text(
                    uploaded ? 'Tap to replace document' : widget.formatHint,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(10),
                      color: uploaded ? _kMid : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing icon
            Icon(
              uploaded ? Icons.edit_outlined : Icons.arrow_forward_ios_rounded,
              color: uploaded ? _kMid : Colors.grey.shade400,
              size: SizeConfig.scale(15),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit button with press-scale animation
// ─────────────────────────────────────────────────────────────────────────────
class _SubmitButton extends StatefulWidget {
  final bool isLoading;
  final String? statusMessage;
  final String label;
  final VoidCallback onPressed;
  const _SubmitButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
    this.statusMessage,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
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
        builder: (context, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: Container(
          width: double.infinity,
          height: SizeConfig.scale(56),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kDark, _kMid],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.scale(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: SizeConfig.scale(20),
                          width: SizeConfig.scale(20),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        ),
                        if (widget.statusMessage != null) ...[
                          SizedBox(width: SizeConfig.scale(12)),
                          Flexible(
                            child: Text(
                              widget.statusMessage!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: SizeConfig.scaledFontSize(13),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.scaledFontSize(16),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: SizeConfig.scale(10)),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: SizeConfig.scale(18),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resume notice — shown after a registration attempt that created the company
// but failed before finishing. The company can't be re-registered, so the
// retry only completes the document upload.
// ─────────────────────────────────────────────────────────────────────────────
class _ResumeNotice extends StatelessWidget {
  const _ResumeNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.scale(12)),
      decoration: BoxDecoration(
        color: _kFieldFocus,
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        border: Border.all(color: _kMid.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: _kPrimary,
            size: SizeConfig.scale(20),
          ),
          SizedBox(width: SizeConfig.scale(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company already registered',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(12),
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                SizedBox(height: SizeConfig.scale(2)),
                Text(
                  'We just need to finish uploading your documents. '
                  'Edits to the details above no longer apply.',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(11),
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
