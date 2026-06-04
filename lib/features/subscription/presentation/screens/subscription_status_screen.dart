import 'dart:async';

import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_request_item.dart';
import 'package:fieldguard/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fieldguard/features/subscription/presentation/widgets/subscription_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// Waiting screen — polls the upgrade requests (newest first) and reflects the
/// latest one's status: PENDING (verifying), APPROVED (done), or REJECTED
/// (with reason + retry). Stops polling once a terminal state is reached.
class SubscriptionStatusScreen extends ConsumerStatefulWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  ConsumerState<SubscriptionStatusScreen> createState() =>
      _SubscriptionStatusScreenState();
}

class _SubscriptionStatusScreenState
    extends ConsumerState<SubscriptionStatusScreen> {
  static const _pollInterval = Duration(seconds: 5);

  Timer? _timer;
  bool _fetching = false;
  bool _initialLoading = true;
  String? _error;
  SubscriptionRequestItem? _latest;
  bool _refreshedOnApproval = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(_pollInterval, (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    _fetching = true;
    final result = await ref.read(subscriptionDataSourceProvider).getRequests();
    if (!mounted) return;
    _fetching = false;

    switch (result) {
      case Success(:final data):
        final latest = data.isNotEmpty ? data.first : null;
        setState(() {
          _latest = latest;
          _initialLoading = false;
          _error = null;
        });
        // Stop polling once there's nothing pending to watch.
        if (latest == null || !latest.isPending) {
          _timer?.cancel();
        }
        // Refresh the plan/seat data once, so screen A shows the new PRO plan.
        if (latest != null && latest.isApproved && !_refreshedOnApproval) {
          _refreshedOnApproval = true;
          ref.invalidate(subscriptionProvider);
        }
      case Failure(:final exception):
        setState(() {
          _initialLoading = false;
          _error = exception is AppException
              ? exception.message
              : 'Could not load request status.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Upgrade Status',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width.clamp(0.0, 520.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.scale(24)),
                child: _buildContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator(color: kSubPrimary));
    }
    if (_error != null && _latest == null) {
      return _StatusView(
        icon: Icons.wifi_off_rounded,
        iconColor: AppColors.red2,
        title: 'Couldn\'t check status',
        message: _error!,
        primaryLabel: 'Retry',
        onPrimary: () {
          setState(() => _initialLoading = true);
          _fetch();
        },
      );
    }

    final latest = _latest;
    if (latest == null) {
      return _StatusView(
        icon: Icons.inbox_outlined,
        iconColor: AppColors.grey2,
        title: 'No upgrade requests',
        message:
            'You have not submitted any upgrade requests yet. Pick a plan to '
            'get started.',
        primaryLabel: 'Back to plans',
        onPrimary: () => Navigator.pop(context),
      );
    }

    switch (latest.status) {
      case SubscriptionRequestStatus.pending:
      case SubscriptionRequestStatus.unknown:
        return _StatusView(
          icon: Icons.hourglass_top_rounded,
          iconColor: kSubMid,
          showSpinner: true,
          title: 'Verifying your payment',
          message:
              'We\'ve received your request${latest.amountNpr != null ? ' for Rs ${latest.amountNpr}' : ''}. '
              'Our team is verifying the payment — this usually takes a little '
              'while. This screen updates automatically.',
        );
      case SubscriptionRequestStatus.approved:
        return _StatusView(
          icon: Icons.verified_rounded,
          iconColor: kSubPrimary,
          title: 'Upgrade approved 🎉',
          message:
              'Your plan is now active. Your new seats and limits are ready to '
              'use.',
          primaryLabel: 'View my plan',
          onPrimary: () => Navigator.pop(context),
        );
      case SubscriptionRequestStatus.rejected:
        return _StatusView(
          icon: Icons.cancel_rounded,
          iconColor: AppColors.red2,
          title: 'Request rejected',
          message: latest.rejectionReason?.isNotEmpty == true
              ? latest.rejectionReason!
              : 'Your upgrade request was rejected. Please review your payment '
                  'and try again.',
          primaryLabel: 'Try again',
          onPrimary: () => Navigator.pop(context),
        );
    }
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final bool showSpinner;
  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  const _StatusView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.showSpinner = false,
    this.primaryLabel,
    this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: SizeConfig.scale(96),
          height: SizeConfig.scale(96),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (showSpinner)
                SizedBox(
                  width: SizeConfig.scale(96),
                  height: SizeConfig.scale(96),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(
                      iconColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              Container(
                width: SizeConfig.scale(72),
                height: SizeConfig.scale(72),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: iconColor, size: SizeConfig.scale(38)),
              ),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.scale(24)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(20),
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
            height: 1.5,
          ),
        ),
        if (primaryLabel != null) ...[
          SizedBox(height: SizeConfig.scale(28)),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: kSubPrimary,
              borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
              child: InkWell(
                borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
                onTap: onPrimary,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.scale(15)),
                  child: Text(
                    primaryLabel!,
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
      ],
    );
  }
}
