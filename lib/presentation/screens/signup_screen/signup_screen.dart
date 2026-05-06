import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/presentation/notifiers/login_notifier.dart';
import 'package:fieldguard/presentation/screens/signup_screen/signup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final passwardController = TextEditingController();
  final phoneNoController = TextEditingController();
  final emailNoController = TextEditingController();

  @override
  void dispose() {
    passwardController.dispose();
    phoneNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SignupProvider>();

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 237, 243, 239),
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

                          /// ================= HEADER =================
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: SizeConfig.scale(30),
                                    width: SizeConfig.scale(30),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF165C3D),
                                      borderRadius: BorderRadius.circular(
                                        SizeConfig.scale(8),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      color: Colors.white,
                                      size: SizeConfig.scale(20),
                                    ),
                                  ),
                                  SizedBox(width: SizeConfig.scale(12)),
                                  Text(
                                    "FieldGuard",
                                    style: TextStyle(
                                      fontSize: SizeConfig.scaledFontSize(18),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF165C3D),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: SizeConfig.heightPercent(2)),
                              Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(26),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: SizeConfig.heightPercent(1)),
                              Text(
                                "Secure access to your agent portal",
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(14),
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: SizeConfig.heightPercent(3)),

                          /// ================= FORM CARD =================
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              maxWidth:
                                  SizeConfig.screenType == ScreenType.large
                                  ? 500
                                  : double.infinity,
                            ),
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                SizeConfig.scale(20),
                              ),
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
                              children: [
                                /// EMAIL
                                _label("Email Address"),
                                SizedBox(height: SizeConfig.heightPercent(1)),

                                _InputField(
                                  controller: emailNoController,
                                  icon: Icons.mail_outline,
                                  hint: "manager@fieldguard.com",
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                /// AUTHORITY
                                _label("Authority"),
                                SizedBox(height: SizeConfig.heightPercent(1)),

                                Container(
                                  height: SizeConfig.scale(50),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    borderRadius: BorderRadius.circular(14),
                                    value: provider.selectedRole,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    items:
                                        {
                                          "Admin": Icons.shield_outlined,
                                          "Manager": Icons.person_outline,
                                        }.entries.map((entry) {
                                          return DropdownMenuItem(
                                            value: entry.key,
                                            child: Row(
                                              children: [
                                                Icon(entry.value),
                                                const SizedBox(width: 8),
                                                Text(entry.key),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        provider.setRole(value);
                                      }
                                    },
                                  ),
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                /// PHONE
                                _label("Mobile Number"),
                                SizedBox(height: SizeConfig.heightPercent(1)),

                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.scale(6),
                                        horizontal: SizeConfig.scale(7),
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          value: provider.selectedKey,
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                          ),
                                          onChanged: (value) {
                                            if (value != null) {
                                              provider.setSelectedCountry(
                                                value,
                                              );
                                            }
                                          },
                                          items: provider.images1.entries.map((
                                            entry,
                                          ) {
                                            return DropdownMenuItem(
                                              value: entry.key,
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundImage:
                                                        NetworkImage(
                                                          entry.value,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(entry.key),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: SizeConfig.scale(10)),

                                    Expanded(
                                      child: SizedBox(
                                        height: SizeConfig.scale(50),
                                        child: TextField(
                                          expands: true,
                                          maxLines: null,
                                          controller: phoneNoController,
                                          decoration: InputDecoration(
                                            hintText: "0000000000",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                /// PASSWORD
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _label("Password"),
                                    Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: const Color(0xFF165C3D),
                                        fontSize: SizeConfig.scaledFontSize(13),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: SizeConfig.heightPercent(1)),

                                SignupPasswordField(
                                  controller: passwardController,
                                ),

                                SizedBox(height: SizeConfig.heightPercent(3)),

                                /// BUTTON
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF165C3D),
                                      padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.scale(16),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          SizeConfig.scale(14),
                                        ),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: SizeConfig.scaledFontSize(16),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                /// FOOTER
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: SizeConfig.scale(16),
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: SizeConfig.scale(6)),
                                    Text(
                                      "SECURE END-TO-END ENCRYPTION",
                                      style: TextStyle(
                                        fontSize: SizeConfig.scaledFontSize(11),
                                        letterSpacing: 1,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),
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

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: SizeConfig.scaledFontSize(12),
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class SignupPasswordField extends ConsumerWidget {
  final TextEditingController controller;

  SignupPasswordField({required this.controller});

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
