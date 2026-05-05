import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive/responsive.dart';
import 'login_footer.dart';
import 'login_header.dart';
import 'login_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 223, 238, 228),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(),

                          /// Header Section
                          const Header(),

                          SizedBox(height: SizeConfig.heightPercent(3)),

                          /// Role Toggle Card
                          const _RoleToggleCard(),

                          SizedBox(height: SizeConfig.heightPercent(2.5)),

                          /// Form Card
                          _buildFormCard(context),

                          const Spacer(),

                          /// Footer
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

  Widget _buildFormCard(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: SizeConfig.screenType == ScreenType.large ? 500 : double.infinity,
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(SizeConfig.scale(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
          const _InputField(
            icon: Icons.mail_outline,
            hint: "manager@fieldguard.com",
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          const _Label(text: "PASSWORD"),
          SizedBox(height: SizeConfig.heightPercent(1)),
          const _PasswordField(),
          SizedBox(height: SizeConfig.heightPercent(1.5)),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Forgot Password?",
              style: TextStyle(
                color: const Color(0xFF1F5A3E),
                fontSize: SizeConfig.scaledFontSize(13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: SizeConfig.heightPercent(2.5)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: handle sign in
              },
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
              child: Text(
                "Sign In",
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleToggleCard extends StatelessWidget {
  const _RoleToggleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: SizeConfig.screenType == ScreenType.large ? 500 : double.infinity,
      ),
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(SizeConfig.scale(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.scale(6)),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
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

class _SelectedRole extends StatelessWidget {
  const _SelectedRole();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.scale(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
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
  final IconData icon;
  final String hint;

  const _InputField({required this.icon, required this.hint});

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
            color: Colors.black.withOpacity(0.1),
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

class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoginProvider>();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              obscureText: provider.hidePassward,
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
            onPressed: () => provider.showPassward(),
            icon: Icon(
              provider.hidePassward
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
