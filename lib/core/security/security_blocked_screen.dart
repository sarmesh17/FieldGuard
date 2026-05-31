import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fieldguard/core/theme/app_colors.dart';

/// Standalone app shown in place of the real app when a rooted / jailbroken
/// device is detected. It is its own [MaterialApp] because it replaces the
/// normal app entirely — the rest of the app (router, providers, services) is
/// never mounted on a compromised device.
class SecurityBlockedApp extends StatelessWidget {
  const SecurityBlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SecurityBlockedScreen(),
    );
  }
}

/// Non-dismissible full-screen warning blocking use on a compromised device.
class SecurityBlockedScreen extends StatelessWidget {
  const SecurityBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    // Block the back gesture/button — there is no app to return to.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: w * 0.28,
                  height: w * 0.28,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.gpp_bad_rounded,
                    size: w * 0.16,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: h * 0.04),
                Text(
                  'Security Check Failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.058,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: h * 0.02),
                Text(
                  'This device appears to be rooted or jailbroken. '
                  'For the security of field data, FieldGuard cannot run on '
                  'compromised devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.04,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: h * 0.02),
                Text(
                  'Please use a device without root/jailbreak access, '
                  'or contact your administrator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.036,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: h * 0.05),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => SystemNavigator.pop(),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Close App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.018),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(w * 0.03),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
