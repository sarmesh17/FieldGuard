import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _phoneNoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                          SizedBox(height: SizeConfig.heightPercent(2.5)),
                          _buildFormCard(),
                          SizedBox(height: SizeConfig.heightPercent(2.5)),
                          const Footer(),
                          const Spacer(),
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
        maxWidth: SizeConfig.screenType == ScreenType.large
            ? 500
            : double.infinity,
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
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
          const _Label(text: "Phone Number"),
          SizedBox(height: SizeConfig.heightPercent(1)),
          _InputField(
            controller: _phoneNoController,
            icon: Icons.phone_outlined,
            hint: "0000000000",
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          const _Label(text: "EMAIL ADDRES (optional)"),
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
              final isLoading = ref.watch(
                loginNotifierProvider.select((s) => s.isLoading),
              );
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5A3E),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.scale(16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
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
