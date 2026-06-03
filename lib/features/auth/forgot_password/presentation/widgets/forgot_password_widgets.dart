import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Brand colours (shared with the login screen) ────────────────────────────
const kFpDark = Color(0xFF1A4731);
const kFpPrimary = Color(0xFF165C3D);
const kFpMid = Color(0xFF2E6F4F);
const kFpLight = Color(0xFF5FBF8F);
const kFpFocus = Color(0xFFF0FAF5);

/// Full-screen gradient backdrop with decorative orbs, matching the login
/// screen so the reset flow feels like part of the same surface.
class BrandBackdrop extends StatelessWidget {
  final Widget child;
  const BrandBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kFpDark, kFpMid, kFpLight],
              stops: [0.0, 0.50, 1.0],
            ),
          ),
          child: SizedBox.expand(),
        ),
        const Positioned(top: -80, right: -80, child: _Orb(size: 240, opacity: 0.08)),
        const Positioned(top: 140, left: -90, child: _Orb(size: 200, opacity: 0.06)),
        const Positioned(bottom: -60, left: -40, child: _Orb(size: 180, opacity: 0.07)),
        SafeArea(child: child),
      ],
    );
  }
}

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

/// Frosted circular back button used in the flow's top-left.
class GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const GlassBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: SizeConfig.scale(40),
          height: SizeConfig.scale(40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: SizeConfig.scale(20),
          ),
        ),
      ),
    );
  }
}

/// White rounded card with the gradient accent stripe, identical in feel to the
/// login form card.
class FpCard extends StatelessWidget {
  final Widget child;
  const FpCard({super.key, required this.child});

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
            color: kFpDark.withValues(alpha: 0.28),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: SizeConfig.scale(3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [kFpDark, kFpMid, kFpLight]),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              SizeConfig.scale(22),
              AppSpacing.md,
              SizeConfig.scale(22),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped input matching the login fields: leading gradient icon chip,
/// focus highlight, optional trailing widget and an inline error line.
class FpPillField extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? trailing;
  final String? errorText;
  final TextAlign textAlign;
  final double? letterSpacing;
  final ValueChanged<String>? onChanged;

  const FpPillField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.obscureText = false,
    this.trailing,
    this.errorText,
    this.textAlign = TextAlign.start,
    this.letterSpacing,
    this.onChanged,
  });

  @override
  State<FpPillField> createState() => _FpPillFieldState();
}

class _FpPillFieldState extends State<FpPillField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: SizeConfig.scale(56),
            decoration: BoxDecoration(
              color: _focused ? kFpFocus : const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
              border: Border.all(
                color: hasError
                    ? Colors.red.shade400
                    : (_focused ? kFpMid : Colors.transparent),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _focused
                      ? kFpPrimary.withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: _focused ? 16 : 6,
                  offset: Offset(0, _focused ? 4 : 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.scale(14),
                right: widget.trailing != null
                    ? SizeConfig.scale(4)
                    : SizeConfig.scale(14),
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
                            ? [kFpMid, kFpDark]
                            : [
                                const Color(0xFFE4EDE8),
                                const Color(0xFFD8E7DE),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color:
                          _focused ? Colors.white : kFpMid.withValues(alpha: 0.70),
                      size: SizeConfig.scale(16),
                    ),
                  ),
                  SizedBox(width: SizeConfig.scale(12)),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      keyboardType: widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                      obscureText: widget.obscureText,
                      textAlign: widget.textAlign,
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: SizeConfig.scaledFontSize(14),
                          letterSpacing: widget.letterSpacing,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                        letterSpacing: widget.letterSpacing,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(
              top: SizeConfig.scale(6),
              left: SizeConfig.scale(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red.shade600,
                  size: SizeConfig.scale(13),
                ),
                SizedBox(width: SizeConfig.scale(5)),
                Expanded(
                  child: Text(
                    widget.errorText!,
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
      ],
    );
  }
}

/// Inline general (non-field) message — red for errors, amber for a rate-limit
/// warning.
class FpInlineMessage extends StatelessWidget {
  final String message;
  final bool warning;
  const FpInlineMessage({super.key, required this.message, this.warning = false});

  @override
  Widget build(BuildContext context) {
    final color = warning ? Colors.orange.shade800 : Colors.red.shade600;
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.scale(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning
                ? Icons.hourglass_top_rounded
                : Icons.error_outline_rounded,
            color: color,
            size: SizeConfig.scale(14),
          ),
          SizedBox(width: SizeConfig.scale(6)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: SizeConfig.scaledFontSize(11),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width gradient primary button with a press-scale animation and a
/// loading spinner, matching the login "Sign In" button.
class FpPrimaryButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const FpPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<FpPrimaryButton> createState() => _FpPrimaryButtonState();
}

class _FpPrimaryButtonState extends State<FpPrimaryButton>
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
      onTapDown: widget.isLoading ? null : (_) => _press.reverse(),
      onTapUp: widget.isLoading ? null : (_) => _press.forward(),
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
              colors: [kFpDark, kFpMid],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
            boxShadow: [
              BoxShadow(
                color: kFpPrimary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
              : Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: SizeConfig.scaledFontSize(16),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Small "SECURE / badge" pill used above the headings.
class FpBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const FpBadge({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.scale(14),
        vertical: SizeConfig.scale(5),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.90),
            size: SizeConfig.scale(12),
          ),
          SizedBox(width: SizeConfig.scale(6)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontSize: SizeConfig.scaledFontSize(9),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
