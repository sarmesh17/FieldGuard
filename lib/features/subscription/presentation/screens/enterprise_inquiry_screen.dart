import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/subscription/data/dto/enterprise_inquiry.dart';
import 'package:fieldguard/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fieldguard/features/subscription/presentation/widgets/subscription_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// ENTERPRISE "Talk to us" — captures a call-back lead. On open it checks for an
/// existing PENDING request: if one is open it shows the "we'll call you" state,
/// otherwise it shows a short form (callback phone + optional staff count and
/// note). This is lead capture only — the actual ENTERPRISE plan is applied by
/// our team after the call.
class EnterpriseInquiryScreen extends ConsumerStatefulWidget {
  const EnterpriseInquiryScreen({super.key});

  @override
  ConsumerState<EnterpriseInquiryScreen> createState() =>
      _EnterpriseInquiryScreenState();
}

class _EnterpriseInquiryScreenState
    extends ConsumerState<EnterpriseInquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _staffCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _loadError;
  String? _submitError;

  /// The open (PENDING) request, if any — drives the "we'll call you" state.
  EnterpriseInquiry? _active;

  /// Most recent already-handled request (CONTACTED / CLOSED), shown as a hint
  /// above the form so a returning admin sees where things stand.
  EnterpriseInquiry? _previous;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _staffCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result =
        await ref.read(subscriptionDataSourceProvider).getEnterpriseInquiries();
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        // Newest first — the latest tells us whether one is still open.
        final latest = data.isNotEmpty ? data.first : null;
        setState(() {
          _active = (latest != null && latest.isPending) ? latest : null;
          _previous = (latest != null && !latest.isPending) ? latest : null;
          _loading = false;
        });
      case Failure(:final exception):
        // Don't block submitting on a failed history fetch — the backend still
        // guards against duplicates with a 409.
        setState(() {
          _loadError = exception is AppException
              ? exception.message
              : 'Could not load your previous requests.';
          _loading = false;
        });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final staff = int.tryParse(_staffCtrl.text.trim());
    final message = _messageCtrl.text.trim();
    final result =
        await ref.read(subscriptionDataSourceProvider).submitEnterpriseInquiry(
              contactPhone: _phoneCtrl.text.trim(),
              expectedStaffCount: staff,
              message: message.isEmpty ? null : message,
            );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Success(:final data):
        setState(() => _active = data);
      case Failure(:final exception):
        // A 409 means a request is already pending — that's not an error from
        // the user's point of view, so re-load to show the open one.
        if (exception is ConflictException) {
          await _load();
          return;
        }
        setState(() => _submitError = exception is AppException
            ? exception.message
            : 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: AppColors.white2,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: kSubPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Talk to us',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width.clamp(0.0, 560.0),
              ),
              child: _buildBody(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kSubPrimary));
    }
    if (_active != null) {
      return _PendingView(inquiry: _active!, onRefresh: _load);
    }
    return _buildForm();
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(SizeConfig.scale(20)),
        children: [
          const _Header(),
          if (_previous != null) ...[
            SizedBox(height: SizeConfig.scale(16)),
            _PreviousStatusBanner(inquiry: _previous!),
          ],
          if (_loadError != null) ...[
            SizedBox(height: SizeConfig.scale(12)),
            _LoadErrorNote(message: _loadError!, onRetry: _load),
          ],
          SizedBox(height: SizeConfig.scale(22)),
          _FieldLabel('Callback number', required: true),
          SizedBox(height: SizeConfig.scale(8)),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              LengthLimitingTextInputFormatter(20),
            ],
            decoration: _inputDecoration(
              hint: 'e.g. 9841000000',
              icon: Icons.phone_rounded,
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Enter a number we can reach you on.';
              if (value.length < 7) return 'That number looks too short.';
              return null;
            },
          ),
          SizedBox(height: SizeConfig.scale(18)),
          _FieldLabel('Expected staff count'),
          SizedBox(height: SizeConfig.scale(8)),
          TextFormField(
            controller: _staffCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
            decoration: _inputDecoration(
              hint: 'Roughly how many people? (optional)',
              icon: Icons.groups_rounded,
            ),
          ),
          SizedBox(height: SizeConfig.scale(18)),
          _FieldLabel('Anything else?'),
          SizedBox(height: SizeConfig.scale(8)),
          TextFormField(
            controller: _messageCtrl,
            maxLines: 4,
            maxLength: 1000,
            decoration: _inputDecoration(
              hint: 'A short note about what you need (optional)',
              icon: null,
            ),
          ),
          if (_submitError != null) ...[
            SizedBox(height: SizeConfig.scale(6)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.red.shade600, size: SizeConfig.scale(16)),
                SizedBox(width: SizeConfig.scale(6)),
                Expanded(
                  child: Text(
                    _submitError!,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: SizeConfig.scaledFontSize(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: SizeConfig.scale(20)),
          _SubmitButton(
            isLoading: _submitting,
            onTap: _submitting ? null : _submit,
          ),
          SizedBox(height: SizeConfig.scale(12)),
          Text(
            'We\'ll set you up with custom seats and pricing over a quick call. '
            'No payment needed now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(11),
              color: AppColors.grey2,
              height: 1.4,
            ),
          ),
          SizedBox(height: SizeConfig.scale(20)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.grey2,
        fontSize: SizeConfig.scaledFontSize(13),
      ),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: kSubPrimary, size: SizeConfig.scale(20)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: SizeConfig.scale(14),
        vertical: SizeConfig.scale(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        borderSide: const BorderSide(color: AppColors.grey3, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        borderSide: const BorderSide(color: kSubPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.6),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
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
            color: kSubPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: SizeConfig.scale(48),
            height: SizeConfig.scale(48),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent_rounded,
                color: Colors.white, size: SizeConfig.scale(26)),
          ),
          SizedBox(width: SizeConfig.scale(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request a call',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: SizeConfig.scaledFontSize(18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: SizeConfig.scale(4)),
                Text(
                  'Tell us how to reach you and our team will call about '
                  'an ENTERPRISE plan.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: SizeConfig.scaledFontSize(12),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(14),
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(14),
              fontWeight: FontWeight.w700,
              color: Colors.red.shade500,
            ),
          ),
      ],
    );
  }
}

class _PreviousStatusBanner extends StatelessWidget {
  final EnterpriseInquiry inquiry;
  const _PreviousStatusBanner({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final contacted = inquiry.isContacted;
    final label = contacted ? 'Our team has reached out' : 'Previous request closed';
    final detail = contacted
        ? 'You can still submit a new request below if you need another call.'
        : 'Submit a new request below if you\'d like to talk again.';
    return Container(
      padding: EdgeInsets.all(SizeConfig.scale(14)),
      decoration: BoxDecoration(
        color: kSubPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        border: Border.all(color: kSubPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            contacted
                ? Icons.mark_chat_read_rounded
                : Icons.history_rounded,
            color: kSubPrimary,
            size: SizeConfig.scale(20),
          ),
          SizedBox(width: SizeConfig.scale(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(13),
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: SizeConfig.scale(3)),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(12),
                    color: AppColors.grey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadErrorNote extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadErrorNote({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            color: AppColors.grey2, size: SizeConfig.scale(16)),
        SizedBox(width: SizeConfig.scale(6)),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: AppColors.grey2,
              fontSize: SizeConfig.scaledFontSize(11),
            ),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text('Retry',
              style: TextStyle(color: kSubPrimary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _SubmitButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: kSubPrimary,
        borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
          onTap: onTap,
          child: Container(
            height: SizeConfig.scale(54),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: SizeConfig.scale(22),
                    height: SizeConfig.scale(22),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded,
                          color: Colors.white, size: SizeConfig.scale(18)),
                      SizedBox(width: SizeConfig.scale(8)),
                      Text(
                        'Request a call',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.scaledFontSize(16),
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
}

/// "We've got your request" — shown when a PENDING inquiry exists (just
/// submitted, or open from a previous visit).
class _PendingView extends StatelessWidget {
  final EnterpriseInquiry inquiry;
  final Future<void> Function() onRefresh;

  const _PendingView({required this.inquiry, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kSubPrimary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(SizeConfig.scale(24)),
        children: [
          SizedBox(height: SizeConfig.scale(20)),
          Center(
            child: Container(
              width: SizeConfig.scale(84),
              height: SizeConfig.scale(84),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kSubPrimary.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.headset_mic_rounded,
                  color: kSubPrimary, size: SizeConfig.scale(42)),
            ),
          ),
          SizedBox(height: SizeConfig.scale(22)),
          Text(
            'We\'ll call you',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(20),
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: SizeConfig.scale(10)),
          Text(
            'Your request is in. Our team will reach out about an ENTERPRISE '
            'plan — usually within a working day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(13),
              color: AppColors.grey,
              height: 1.5,
            ),
          ),
          SizedBox(height: SizeConfig.scale(24)),
          _DetailCard(inquiry: inquiry),
          SizedBox(height: SizeConfig.scale(20)),
          Center(
            child: TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded,
                  color: kSubPrimary, size: 18),
              label: const Text(
                'Check status',
                style: TextStyle(
                  color: kSubPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final EnterpriseInquiry inquiry;
  const _DetailCard({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.scale(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _row(Icons.phone_rounded, 'Callback number', inquiry.contactPhone),
          if (inquiry.expectedStaffCount != null) ...[
            _divider(),
            _row(Icons.groups_rounded, 'Expected staff',
                '${inquiry.expectedStaffCount}'),
          ],
          if (inquiry.message != null && inquiry.message!.isNotEmpty) ...[
            _divider(),
            _row(Icons.notes_rounded, 'Your note', inquiry.message!),
          ],
          if (inquiry.createdAt != null) ...[
            _divider(),
            _row(Icons.schedule_rounded, 'Submitted',
                _fmtDate(inquiry.createdAt!)),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.scale(12)),
        child: const Divider(height: 1, color: AppColors.white4),
      );

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kSubPrimary, size: SizeConfig.scale(18)),
        SizedBox(width: SizeConfig.scale(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(11),
                  color: AppColors.grey2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: SizeConfig.scale(3)),
              Text(
                value,
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = d.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}
