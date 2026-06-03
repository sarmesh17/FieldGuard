import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_response.dart';
import 'package:fieldguard/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fieldguard/features/subscription/presentation/screens/enterprise_inquiry_screen.dart';
import 'package:fieldguard/features/subscription/presentation/screens/subscription_status_screen.dart';
import 'package:fieldguard/features/subscription/presentation/screens/upgrade_screen.dart';
import 'package:fieldguard/features/subscription/presentation/widgets/subscription_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          backgroundColor: const Color(0xFFF5F6FA),
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
                color: Color(0xff111111),
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Request status',
                icon: const Icon(Icons.receipt_long_rounded, color: kSubPrimary),
                onPressed: () => _openStatus(context),
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
                _CurrentPlanBanner(subscription: current),
                SizedBox(height: SizeConfig.scale(14)),
                SeatUsageCard(subscription: current),
                SizedBox(height: SizeConfig.scale(22)),
                Text(
                  'Available plans',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(15),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff111827),
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
  const _CurrentPlanBanner({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final expired = subscription.expired;
    final expiry = subscription.expiresAt;
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
              Text(
                subscription.plan,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeConfig.scaledFontSize(30),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
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
                    ? const Color(0xffE53935).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(SizeConfig.scale(10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    expired
                        ? Icons.error_outline_rounded
                        : Icons.event_available_rounded,
                    color: Colors.white,
                    size: SizeConfig.scale(13),
                  ),
                  SizedBox(width: SizeConfig.scale(5)),
                  Text(
                    expired
                        ? 'Expired on ${_fmtDate(expiry)}'
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
