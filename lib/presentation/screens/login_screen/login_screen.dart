import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../notifiers/login_notifier.dart';
import 'login_footer.dart';
import 'login_header.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    await ref.read(loginNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    final state = ref.read(loginNotifierProvider);

    if (state.errorMessage != null) {
      Fluttertoast.showToast(
        msg: state.errorMessage!,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } else if (state.user != null) {
      Fluttertoast.showToast(
        msg: 'Welcome, ${state.user!.email}!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      // TODO: navigate to home/dashboard once that route exists
      // context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 223, 238, 228),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, innerConstraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: innerConstraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(),
                          const Header(),
                          SizedBox(height: SizeConfig.heightPercent(3)),
                          const _RoleToggleCard(),
                          SizedBox(height: SizeConfig.heightPercent(2.5)),
                          _buildFormCard(),
                          const Spacer(),
                          const Footer(),
                          SizedBox(height: SizeConfig.heightPercent(2)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth:
            SizeConfig.screenType == ScreenType.large ? 500 : double.infinity,
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(SizeConfig.scale(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Label(text: "EMAIL ADDRESS"),
          SizedBox(height: SizeConfig.heightPercent(1)),
          _InputField(
            controller: _emailController,
            icon: Icons.mail_outline,
            hint: "manager@fieldguard.com",
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          const _Label(text: "PASSWORD"),
          SizedBox(height: SizeConfig.heightPercent(1)),
          _PasswordField(controller: _passwordController),
          SizedBox(height: SizeConfig.heightPercent(1.5)),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                // TODO: navigate to forgot password screen
              },
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  color: const Color(0xFF1F5A3E),
                  fontSize: SizeConfig.scaledFontSize(13),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.heightPercent(2.5)),
          Consumer(
            builder: (context, ref, _) {
              final isLoading =
                  ref.watch(loginNotifierProvider.select((s) => s.isLoading));
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5A3E),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.scale(16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(SizeConfig.scale(14)),
                    ),
                    elevation: 4,
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: SizeConfig.scale(20),
                          width: SizeConfig.scale(20),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
          SizedBox(height: SizeConfig.heightPercent(1.5)),
          Center(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.signup),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: SizeConfig.scaledFontSize(13),
                  ),
                  children: const [
                    TextSpan(text: "Don't have an account?  "),
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF1F5A3E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Private sub-widgets ──────────────────────────────────────────────────────

class _RoleToggleCard extends StatelessWidget {
  const _RoleToggleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth:
            SizeConfig.screenType == ScreenType.large ? 500 : double.infinity,
      ),
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(SizeConfig.scale(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.scale(6)),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(SizeConfig.scale(40)),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Expanded(child: _SelectedRole()),
            Expanded(child: _UnselectedRole()),
          ],
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.scale(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            color: const Color(0xFF1F5A3E),
            size: SizeConfig.scale(18),
          ),
          SizedBox(width: SizeConfig.scale(6)),
          Flexible(
            child: Text(
              "Manager",
              style: TextStyle(
                color: const Color(0xFF1F5A3E),
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.scaledFontSize(14),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnselectedRole extends StatelessWidget {
  const _UnselectedRole();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.scale(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            color: Colors.grey,
            size: SizeConfig.scale(18),
          ),
          SizedBox(width: SizeConfig.scale(6)),
          Flexible(
            child: Text(
              "Admin",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.scaledFontSize(14),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: SizeConfig.scaledFontSize(11),
        letterSpacing: 1,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;

  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: SizeConfig.scale(20)),
          SizedBox(width: SizeConfig.scale(12)),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: SizeConfig.scaledFontSize(14),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: SizeConfig.scale(14),
                ),
              ),
              style: TextStyle(fontSize: SizeConfig.scaledFontSize(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends ConsumerWidget {
  final TextEditingController controller;

  const _PasswordField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidePassword = ref.watch(
      loginNotifierProvider.select((s) => s.hidePassword),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.grey.shade600,
            size: SizeConfig.scale(20),
          ),
          SizedBox(width: SizeConfig.scale(12)),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: hidePassword,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "••••••••",
                contentPadding: EdgeInsets.symmetric(
                  vertical: SizeConfig.scale(14),
                ),
              ),
              style: TextStyle(fontSize: SizeConfig.scaledFontSize(14)),
            ),
          ),
          IconButton(
            onPressed: () => ref
                .read(loginNotifierProvider.notifier)
                .togglePasswordVisibility(),
            icon: Icon(
              hidePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: SizeConfig.scale(20),
            ),
          ),
        ],
      ),
    );
  }
}
