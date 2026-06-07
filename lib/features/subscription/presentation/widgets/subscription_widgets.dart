import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_response.dart';
import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

// ─── Palette (matches the admin profile green) ───────────────────────────────
const kSubDark = AppColors.green;
const kSubPrimary = AppColors.green;
const kSubMid = AppColors.green;
const kSubLight = AppColors.gradientStart;
const kSubAccent = AppColors.blue; // PRO highlight

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
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                unlimited ? '$used / ∞' : '$used / $limit',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  fontWeight: FontWeight.w800,
                  color: full ? AppColors.red2 : kSubPrimary,
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
              backgroundColor: AppColors.backgroundAlt,
              valueColor: AlwaysStoppedAnimation(
                full ? AppColors.red2 : kSubMid,
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
              color: full ? AppColors.red2 : AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly SMS meter (shop receipts), enforced on every plan. `overQuota`
/// shows a red "paused" banner + upgrade CTA; near-limit shows a soft amber
/// nudge; ENTERPRISE (unlimited) just shows "Unlimited / ∞".
class SmsUsageCard extends StatelessWidget {
  final SmsUsage usage;
  final VoidCallback? onUpgrade;
  const SmsUsageCard({super.key, required this.usage, this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final unlimited = usage.unlimited;
    final over = usage.overQuota;
    final near = usage.nearLimit;
    final quota = usage.quota ?? 0;
    final remaining = usage.remaining ?? (quota - usage.used);
    final barColor =
        over ? AppColors.red2 : (near ? AppColors.orange2 : kSubMid);

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
              Icon(Icons.sms_outlined,
                  color: barColor, size: SizeConfig.scale(20)),
              SizedBox(width: SizeConfig.scale(8)),
              Text(
                'SMS this month',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                unlimited ? '${usage.used} / ∞' : '${usage.used} / $quota',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  fontWeight: FontWeight.w800,
                  color: over ? AppColors.red2 : kSubPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.scale(12)),
          ClipRRect(
            borderRadius: BorderRadius.circular(SizeConfig.scale(8)),
            child: LinearProgressIndicator(
              value: unlimited ? null : usage.fraction,
              minHeight: SizeConfig.scale(8),
              backgroundColor: AppColors.backgroundAlt,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          SizedBox(height: SizeConfig.scale(10)),
          Text(
            unlimited
                ? 'Unlimited SMS on this plan.'
                : over
                    ? 'Monthly SMS limit reached ($quota/$quota).'
                    : '$remaining SMS left this month.',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(12),
              color: over
                  ? AppColors.red2
                  : (near ? AppColors.brown : AppColors.grey),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (over) ...[
            SizedBox(height: SizeConfig.scale(12)),
            _blockedBanner(),
          ] else if (near) ...[
            SizedBox(height: SizeConfig.scale(10)),
            _nearWarning(remaining),
          ],
        ],
      ),
    );
  }

  Widget _blockedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.scale(14)),
      decoration: BoxDecoration(
        color: AppColors.red6,
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        border: Border.all(color: AppColors.red2.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppColors.red2, size: SizeConfig.scale(18)),
              SizedBox(width: SizeConfig.scale(8)),
              Expanded(
                child: Text(
                  'Shop receipts paused',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(13),
                    fontWeight: FontWeight.w800,
                    color: AppColors.red9,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.scale(6)),
          Text(
            "You've used all your SMS this month, so receipt texts are "
            'paused. Upgrade your plan to resume.',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(12),
              color: AppColors.red9,
              height: 1.4,
            ),
          ),
          if (onUpgrade != null) ...[
            SizedBox(height: SizeConfig.scale(12)),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.red2,
                borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                  onTap: onUpgrade,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: SizeConfig.scale(11)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upgrade_rounded,
                            color: Colors.white, size: SizeConfig.scale(18)),
                        SizedBox(width: SizeConfig.scale(8)),
                        Text(
                          'Upgrade plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: SizeConfig.scaledFontSize(13),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _nearWarning(int remaining) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.scale(12)),
      decoration: BoxDecoration(
        color: AppColors.orange8,
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        border: Border.all(color: AppColors.orange2.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.orange2, size: SizeConfig.scale(18)),
          SizedBox(width: SizeConfig.scale(8)),
          Expanded(
            child: Text(
              'Only $remaining SMS left this month. Upgrade soon to avoid '
              'pausing shop receipts.',
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(12),
                color: AppColors.brown,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
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
          color: isCurrent ? accent : AppColors.grey3,
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
                plan.label,
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(18),
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
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
                        color: AppColors.grey2,
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
          SizedBox(height: SizeConfig.scale(6)),
          _feature(
            Icons.sms_outlined,
            plan.smsQuota == null
                ? 'Unlimited SMS / month'
                : '${plan.smsQuota} SMS / month',
          ),
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
                  isContact ? 'Talk to us' : 'Upgrade to ${plan.label}',
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
        Icon(icon, size: SizeConfig.scale(16), color: AppColors.grey),
        SizedBox(width: SizeConfig.scale(8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(13),
              color: AppColors.blue2,
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
