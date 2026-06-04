import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/legal/presentation/screens/legal_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

const _kPrimary = AppColors.green12;

/// A checkbox + rich-text line asking the user to accept the Terms & Conditions
/// and Privacy Policy. The two document names are tappable and open the
/// [LegalScreen] on the matching tab.
///
/// Designed to sit inside the white login/signup form cards. Used to gate the
/// sign-in / register actions so consent is recorded before either proceeds.
class LegalConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const LegalConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  void _openLegal(BuildContext context, LegalTab tab) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalScreen(initialTab: tab)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: _kPrimary,
      fontWeight: FontWeight.w700,
      fontSize: SizeConfig.scaledFontSize(12),
      decoration: TextDecoration.underline,
      decorationColor: _kPrimary,
    );
    final baseStyle = TextStyle(
      color: Colors.grey.shade600,
      fontSize: SizeConfig.scaledFontSize(12),
      height: 1.45,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tappable checkbox with a comfortable tap target.
        GestureDetector(
          onTap: () => onChanged(!value),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(
              top: SizeConfig.scale(1),
              right: SizeConfig.scale(10),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: SizeConfig.scale(20),
              height: SizeConfig.scale(20),
              decoration: BoxDecoration(
                color: value ? _kPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(SizeConfig.scale(6)),
                border: Border.all(
                  color: value ? _kPrimary : Colors.grey.shade400,
                  width: 1.6,
                ),
              ),
              child: value
                  ? Icon(
                      Icons.check_rounded,
                      size: SizeConfig.scale(14),
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: SizeConfig.scale(1)),
            child: RichText(
              text: TextSpan(
                style: baseStyle,
                children: [
                  const TextSpan(text: 'I have read and agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openLegal(context, LegalTab.terms),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openLegal(context, LegalTab.privacy),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
