import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:fieldguard/features/subscription/presentation/widgets/subscription_widgets.dart';
import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// Shown when a create-staff call returns 402 (seat limit reached). Explains
/// the limit (using the backend's [message]) and offers to open the plans
/// screen so the admin can upgrade.
Future<void> showSeatLimitDialog(BuildContext context, String message) async {
  final upgrade = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.scale(24)),
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.scale(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: SizeConfig.scale(64),
              height: SizeConfig.scale(64),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kSubPrimary, kSubMid],
                ),
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: SizeConfig.scale(32)),
            ),
            SizedBox(height: SizeConfig.scale(18)),
            Text(
              'Seat limit reached',
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(19),
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: SizeConfig.scale(10)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(13),
                color: AppColors.grey,
                height: 1.45,
              ),
            ),
            SizedBox(height: SizeConfig.scale(24)),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.scale(14),
                      ),
                      foregroundColor: AppColors.grey,
                    ),
                    child: Text(
                      'Not now',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.scale(10)),
                Expanded(
                  child: Material(
                    color: kSubPrimary,
                    borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
                      onTap: () => Navigator.pop(ctx, true),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: SizeConfig.scale(14),
                        ),
                        child: Text(
                          'View plans',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: SizeConfig.scaledFontSize(15),
                            fontWeight: FontWeight.w700,
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

  if (upgrade == true && context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }
}
