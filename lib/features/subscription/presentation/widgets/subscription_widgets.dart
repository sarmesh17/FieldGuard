import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_response.dart';
import 'package:flutter/material.dart';

// ─── Palette (matches the admin profile green) ───────────────────────────────
const kSubDark = Color(0xFF072A1C);
const kSubPrimary = Color(0xFF0E5A3B);
const kSubMid = Color(0xFF1D7A51);
const kSubLight = Color(0xFF2E6F4F);
const kSubAccent = Color(0xFF6558FF); // PRO highlight

/// "Unlimited" for a null limit (ENTERPRISE), else the number.
String planLimitLabel(int? value) => value == null ? 'Unlimited' : '$value';

/// Seat usage meter: staffUsed / staffSeatLimit with a progress bar and a
/// remaining hint. Shows "Unlimited" instead of a bar when there's no limit.
class SeatUsageCard extends StatelessWidget {
  final CurrentSubscription subscription;
  const SeatUsageCard({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final limit = subscription.staffSeatLimit;
    final used = subscription.staffUsed;
    final unlimited = limit == null;
    final fraction =
        (unlimited || limit == 0) ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final full = !unlimited && used >= limit;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.scale(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded,
                  color: kSubPrimary, size: SizeConfig.scale(20)),
              SizedBox(width: SizeConfig.scale(8)),
              Text(
                'Staff seats',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff111827),
                ),
              ),
              const Spacer(),
              Text(
                unlimited ? '$used / ∞' : '$used / $limit',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  fontWeight: FontWeight.w800,
                  color: full ? const Color(0xffE53935) : kSubPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.scale(12)),
          ClipRRect(
            borderRadius: BorderRadius.circular(SizeConfig.scale(8)),
            child: LinearProgressIndicator(
              value: unlimited ? null : fraction,
              minHeight: SizeConfig.scale(8),
              backgroundColor: const Color(0xffEAEFEC),
              valueColor: AlwaysStoppedAnimation(
                full ? const Color(0xffE53935) : kSubMid,
              ),
            ),
          ),
          SizedBox(height: SizeConfig.scale(10)),
          Text(
            unlimited
                ? 'Unlimited staff seats on this plan.'
                : full
                    ? 'All seats used. Upgrade to add more staff.'
                    : '${subscription.staffRemaining ?? 0} seat(s) remaining.',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(12),
              color: full ? const Color(0xffE53935) : const Color(0xff6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single plan in the catalogue. Highlights the company's current plan, shows
/// a price, seat/member limits, and an action: "Current plan", "Upgrade", or
/// "Talk to us" (ENTERPRISE / contactSales).
class PlanCard extends StatelessWidget {
  final PlanOption plan;
  final bool isCurrent;
  final VoidCallback? onUpgrade;
  final VoidCallback? onContactSales;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isCurrent,
    this.onUpgrade,
    this.onContactSales,
  });

  @override
  Widget build(BuildContext context) {
    final accent = plan.contactSales ? kSubAccent : kSubPrimary;
    final priceLabel = plan.contactSales || plan.priceNpr == null
        ? 'Custom'
        : plan.priceNpr == 0
            ? 'Free'
            : 'Rs ${plan.priceNpr}';
    final billingSuffix =
        (plan.billing == 'monthly' && (plan.priceNpr ?? 0) > 0) ? ' /mo' : '';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: SizeConfig.scale(14)),
      padding: EdgeInsets.all(SizeConfig.scale(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
        border: Border.all(
          color: isCurrent ? accent : const Color(0xffE8E3DD),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.code,
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(18),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff111827),
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: SizeConfig.scale(8)),
              if (isCurrent) _pill('CURRENT', accent),
              if (plan.contactSales && !isCurrent)
                _pill('CONTACT SALES', kSubAccent),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceLabel,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(18),
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  if (billingSuffix.isNotEmpty)
                    Text(
                      'per month',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(10),
                        color: const Color(0xff9CA3AF),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: SizeConfig.scale(12)),
          _feature(Icons.badge_outlined,
              '${planLimitLabel(plan.staffSeats)} staff seat(s)'),
          SizedBox(height: SizeConfig.scale(6)),
          _feature(Icons.people_outline_rounded,
              '${planLimitLabel(plan.totalMembers)} total member(s)'),
          if (!isCurrent &&
              (onUpgrade != null || (plan.contactSales && onContactSales != null))) ...[
            SizedBox(height: SizeConfig.scale(16)),
            _actionButton(accent),
          ],
        ],
      ),
    );
  }

  Widget _actionButton(Color accent) {
    final isContact = plan.contactSales;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: isContact ? Colors.white : accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
          side: isContact ? BorderSide(color: accent, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
          onTap: isContact ? onContactSales : onUpgrade,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.scale(13)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isContact ? Icons.support_agent_rounded : Icons.upgrade_rounded,
                  color: isContact ? accent : Colors.white,
                  size: SizeConfig.scale(18),
                ),
                SizedBox(width: SizeConfig.scale(8)),
                Text(
                  isContact ? 'Talk to us' : 'Upgrade to ${plan.code}',
                  style: TextStyle(
                    color: isContact ? accent : Colors.white,
                    fontSize: SizeConfig.scaledFontSize(14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: SizeConfig.scale(16), color: const Color(0xff6B7280)),
        SizedBox(width: SizeConfig.scale(8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(13),
              color: const Color(0xff374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.scale(8),
        vertical: SizeConfig.scale(3),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SizeConfig.scale(8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: SizeConfig.scaledFontSize(9),
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
