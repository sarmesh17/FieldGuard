import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_response.dart';
import 'package:fieldguard/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fieldguard/features/subscription/presentation/screens/enterprise_inquiry_screen.dart';
import 'package:fieldguard/features/subscription/presentation/screens/invoices_screen.dart';
import 'package:fieldguard/features/subscription/presentation/screens/subscription_status_screen.dart';
import 'package:fieldguard/features/subscription/presentation/screens/upgrade_screen.dart';
import 'package:fieldguard/features/subscription/presentation/widgets/subscription_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// Screen A — current plan, seat usage and the plan catalogue. Entry point for
/// upgrading (PRO) or contacting sales (ENTERPRISE).
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  void _openUpgrade(
    BuildContext context,
    PlanOption plan,
    PaymentInfo? payment,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpgradeScreen(plan: plan, payment: payment),
      ),
    );
  }

  void _openInvoices(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InvoicesScreen()),
    );
  }

  void _openStatus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionStatusScreen()),
    );
  }

  void _contactSales(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EnterpriseInquiryScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subscriptionProvider);

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: kSubPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Subscription',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Invoices',
                icon: const Icon(Icons.receipt_long_rounded, color: kSubPrimary),
                onPressed: () => _openInvoices(context),
              ),
            ],
          ),
          body: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: kSubPrimary),
            ),
            error: (err, _) => _ErrorBody(
              message: err.toString(),
              onRetry: () => ref.invalidate(subscriptionProvider),
            ),
            data: (data) => RefreshIndicator(
              color: kSubPrimary,
              onRefresh: () async => ref.invalidate(subscriptionProvider),
              child: _Body(
                data: data,
                onUpgrade: (plan) => _openUpgrade(context, plan, data.payment),
                onContactSales: () => _contactSales(context),
                onViewStatus: () => _openStatus(context),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final SubscriptionResponse data;
  final void Function(PlanOption plan) onUpgrade;
  final VoidCallback onContactSales;
  final VoidCallback onViewStatus;

  const _Body({
    required this.data,
    required this.onUpgrade,
    required this.onContactSales,
    required this.onViewStatus,
  });

  @override
  Widget build(BuildContext context) {
    final current = data.subscription;
    final maxW = MediaQuery.of(context).size.width.clamp(0.0, 600.0);

    // SMS over-quota CTA: prefer the next payable plan (FREE → PRO), else fall
    // back to "Talk to us" when the only step up is ENTERPRISE (contactSales).
    PlanOption? payableUpgrade;
    bool hasContactPlan = false;
    String currentLabel = current.plan; // fall back to the code
    for (final p in data.plans) {
      if (p.code == current.plan) {
        currentLabel = p.label;
        continue;
      }
      if (p.contactSales) {
        hasContactPlan = true;
        continue;
      }
      if ((p.priceNpr ?? 0) > 0 && payableUpgrade == null) payableUpgrade = p;
    }
    final smsUpgradeCta = payableUpgrade != null
        ? () => onUpgrade(payableUpgrade!)
        : (hasContactPlan ? onContactSales : null);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CurrentPlanBanner(
                  subscription: current,
                  planLabel: currentLabel,
                ),
                if (current.expired) ...[
                  SizedBox(height: SizeConfig.scale(12)),
                  _ExpiredLockBanner(onUpgrade: smsUpgradeCta),
                ],
                SizedBox(height: SizeConfig.scale(14)),
                SeatUsageCard(subscription: current),
                if (current.smsUsage != null) ...[
                  SizedBox(height: SizeConfig.scale(14)),
                  SmsUsageCard(
                    usage: current.smsUsage!,
                    onUpgrade: smsUpgradeCta,
                  ),
                ],
                SizedBox(height: SizeConfig.scale(22)),
                Text(
                  'Available plans',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(15),
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: SizeConfig.scale(12)),
                for (final plan in data.plans)
                  PlanCard(
                    plan: plan,
                    isCurrent: plan.code == current.plan,
                    onUpgrade: (plan.code != current.plan &&
                            !plan.contactSales &&
                            (plan.priceNpr ?? 0) > 0)
                        ? () => onUpgrade(plan)
                        : null,
                    onContactSales:
                        plan.contactSales ? onContactSales : null,
                  ),
                SizedBox(height: SizeConfig.scale(6)),
                Center(
                  child: TextButton.icon(
                    onPressed: onViewStatus,
                    icon: const Icon(Icons.history_rounded,
                        color: kSubPrimary, size: 18),
                    label: const Text(
                      'View upgrade request status',
                      style: TextStyle(
                        color: kSubPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.scale(20)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  final CurrentSubscription subscription;
  final String planLabel;
  const _CurrentPlanBanner({
    required this.subscription,
    required this.planLabel,
  });

  @override
  Widget build(BuildContext context) {
    final expired = subscription.expired;
    final expiry = subscription.expiresAt;
    final isFreeTrial = subscription.plan == 'FREE' && !expired;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.scale(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kSubDark, kSubPrimary, kSubMid],
        ),
        borderRadius: BorderRadius.circular(SizeConfig.scale(22)),
        boxShadow: [
          BoxShadow(
            color: kSubPrimary.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT PLAN',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: SizeConfig.scaledFontSize(11),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: SizeConfig.scale(6)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  planLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: SizeConfig.scaledFontSize(30),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.scale(8)),
              if (subscription.priceNpr > 0)
                Padding(
                  padding: EdgeInsets.only(bottom: SizeConfig.scale(5)),
                  child: Text(
                    'Rs ${subscription.priceNpr}'
                    '${subscription.billing == 'monthly' ? '/mo' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: SizeConfig.scaledFontSize(13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (expiry != null) ...[
            SizedBox(height: SizeConfig.scale(10)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.scale(10),
                vertical: SizeConfig.scale(5),
              ),
              decoration: BoxDecoration(
                color: expired
                    ? AppColors.red2.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(SizeConfig.scale(10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    expired
                        ? Icons.error_outline_rounded
                        : isFreeTrial
                            ? Icons.hourglass_bottom_rounded
                            : Icons.event_available_rounded,
                    color: Colors.white,
                    size: SizeConfig.scale(13),
                  ),
                  SizedBox(width: SizeConfig.scale(5)),
                  Text(
                    expired
                        ? 'Expired on ${_fmtDate(expiry)}'
                        : isFreeTrial
                            ? 'Free Trial · ${_daysLeft(expiry)}'
                            : 'Renews / expires ${_fmtDate(expiry)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: SizeConfig.scaledFontSize(11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// Human countdown to [expiry] for the Free Trial chip.
  String _daysLeft(DateTime expiry) {
    final days = expiry.difference(DateTime.now()).inDays;
    if (days <= 0) return 'ends today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }
}

/// Prominent lock shown when the plan has expired — adding staff returns 402
/// and SMS is paused (existing data/team stay safe). CTA → upgrade flow.
class _ExpiredLockBanner extends StatelessWidget {
  final VoidCallback? onUpgrade;
  const _ExpiredLockBanner({this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: AppColors.red6,
        borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        border: Border.all(color: AppColors.red2.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded,
                  color: AppColors.red2, size: SizeConfig.scale(20)),
              SizedBox(width: SizeConfig.scale(8)),
              Expanded(
                child: Text(
                  'Plan expired',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(15),
                    fontWeight: FontWeight.w800,
                    color: AppColors.red9,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.scale(6)),
          Text(
            'Subscribe to add staff and send shop receipt SMS again. Your '
            'existing data and team stay safe.',
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
                        EdgeInsets.symmetric(vertical: SizeConfig.scale(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upgrade_rounded,
                            color: Colors.white, size: SizeConfig.scale(18)),
                        SizedBox(width: SizeConfig.scale(8)),
                        Text(
                          'Subscribe now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: SizeConfig.scaledFontSize(14),
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
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.scale(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red.shade400, size: SizeConfig.scale(48)),
            SizedBox(height: SizeConfig.scale(14)),
            Text(
              'Could not load your plan',
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(16),
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: SizeConfig.scale(6)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(12),
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: SizeConfig.scale(18)),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kSubPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
