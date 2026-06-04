import 'dart:io';

import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/subscription/data/dto/subscription_response.dart';
import 'package:fieldguard/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fieldguard/features/subscription/presentation/screens/subscription_status_screen.dart';
import 'package:fieldguard/features/subscription/presentation/widgets/subscription_widgets.dart';
import 'package:fieldguard/features/uploads/image_upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// Screen C — pay-by-QR upgrade. The admin picks a duration, pays the shown
/// amount via the backend-provided QR, uploads the payment screenshot, and
/// submits the request for verification.
class UpgradeScreen extends ConsumerStatefulWidget {
  final PlanOption plan;
  final PaymentInfo? payment;

  const UpgradeScreen({super.key, required this.plan, this.payment});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  static const _monthOptions = [1, 3, 6, 12];

  int _months = 1;
  File? _proofImage;
  String? _proofImageKey;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  int get _amount => (widget.plan.priceNpr ?? 0) * _months;

  Future<void> _pickProof() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null) return;
      setState(() {
        _proofImage = File(path);
        _proofImageKey = null;
        _errorMessage = null;
      });
      await _uploadProof(path);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Could not pick image: $e');
    }
  }

  Future<void> _uploadProof(String path) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });
    try {
      final companyId = await Session.companyId() ?? 0;
      final uploadService = ImageUploadService(DioClient.createDio());
      final result = await uploadService.upload(
        filePath: path,
        category: 'payments',
        entityId: companyId,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _proofImageKey = result.imageKey;
        _isUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _proofImage = null;
        _errorMessage = 'Screenshot upload failed. Please try again.';
      });
    }
  }

  Future<void> _submit() async {
    final imageKey = _proofImageKey;
    if (imageKey == null) {
      setState(() => _errorMessage = 'Upload your payment screenshot first.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await ref.read(subscriptionDataSourceProvider).submitRequest(
          months: _months,
          paymentProofImageKey: imageKey,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success():
        _goToStatus();
      case Failure(:final exception):
        // A 409 means a request is already pending — that's not an error from
        // the user's point of view, so head to the waiting screen too.
        if (exception is ConflictException) {
          _goToStatus();
          return;
        }
        setState(() => _errorMessage = exception is AppException
            ? exception.message
            : 'Something went wrong. Please try again.');
    }
  }

  void _goToStatus() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionStatusScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = widget.payment?.qrImageUrl;
    final note = widget.payment?.paymentNote;

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
            title: Text(
              'Upgrade to ${widget.plan.code}',
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.all(SizeConfig.scale(16)),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width.clamp(0.0, 600.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _stepLabel('1', 'Choose duration'),
                      SizedBox(height: SizeConfig.scale(10)),
                      _DurationSelector(
                        options: _monthOptions,
                        selected: _months,
                        onSelect: (m) => setState(() => _months = m),
                      ),
                      SizedBox(height: SizeConfig.scale(14)),
                      _AmountCard(amount: _amount, months: _months),

                      SizedBox(height: SizeConfig.scale(24)),
                      _stepLabel('2', 'Scan & pay'),
                      SizedBox(height: SizeConfig.scale(10)),
                      _QrCard(qrUrl: qrUrl, note: note),

                      SizedBox(height: SizeConfig.scale(24)),
                      _stepLabel('3', 'Upload payment screenshot'),
                      SizedBox(height: SizeConfig.scale(10)),
                      _ProofPicker(
                        image: _proofImage,
                        uploaded: _proofImageKey != null,
                        isUploading: _isUploading,
                        progress: _uploadProgress,
                        onTap: _isUploading ? null : _pickProof,
                      ),

                      if (_errorMessage != null) ...[
                        SizedBox(height: SizeConfig.scale(12)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: Colors.red.shade600,
                                size: SizeConfig.scale(16)),
                            SizedBox(width: SizeConfig.scale(6)),
                            Expanded(
                              child: Text(
                                _errorMessage!,
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

                      SizedBox(height: SizeConfig.scale(24)),
                      _SubmitButton(
                        enabled: _proofImageKey != null && !_isSubmitting,
                        isLoading: _isSubmitting,
                        onTap: _submit,
                      ),
                      SizedBox(height: SizeConfig.scale(12)),
                      Text(
                        'After you submit, our team verifies the payment and '
                        'activates your plan. You can track the status on the '
                        'next screen.',
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stepLabel(String number, String text) {
    return Row(
      children: [
        Container(
          width: SizeConfig.scale(24),
          height: SizeConfig.scale(24),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: kSubPrimary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.scaledFontSize(12),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(width: SizeConfig.scale(10)),
        Text(
          text,
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(15),
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelect;

  const _DurationSelector({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SizeConfig.scale(10),
      runSpacing: SizeConfig.scale(10),
      children: options.map((m) {
        final isSel = m == selected;
        return GestureDetector(
          onTap: () => onSelect(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.scale(18),
              vertical: SizeConfig.scale(10),
            ),
            decoration: BoxDecoration(
              color: isSel ? kSubPrimary : Colors.white,
              borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
              border: Border.all(
                color: isSel ? kSubPrimary : AppColors.grey3,
                width: 1.5,
              ),
            ),
            child: Text(
              m == 1 ? '1 month' : '$m months',
              style: TextStyle(
                color: isSel ? Colors.white : AppColors.blue2,
                fontWeight: FontWeight.w700,
                fontSize: SizeConfig.scaledFontSize(13),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final int amount;
  final int months;
  const _AmountCard({required this.amount, required this.months});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: kSubPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        border: Border.all(color: kSubPrimary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Text(
            'Amount to pay',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(13),
              color: AppColors.blue2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Rs $amount',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(22),
              fontWeight: FontWeight.w900,
              color: kSubPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final String? qrUrl;
  final String? note;
  const _QrCard({required this.qrUrl, required this.note});

  void _openFullScreen(BuildContext context) {
    if (qrUrl == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenQrViewer(qrUrl: qrUrl!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrSize = SizeConfig.scale(200);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.scale(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tap the QR (or the expand button) to open it full-screen, so it's
          // big enough for another phone to scan.
          GestureDetector(
            onTap: qrUrl == null ? null : () => _openFullScreen(context),
            child: Stack(
              children: [
                Container(
                  width: qrSize,
                  height: qrSize,
                  decoration: BoxDecoration(
                    color: AppColors.white2,
                    borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: qrUrl == null
                      ? const _QrPlaceholder(
                          icon: Icons.qr_code_2_rounded,
                          text: 'QR not available',
                        )
                      : Image.network(
                          qrUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: kSubPrimary,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stack) =>
                              const _QrPlaceholder(
                            icon: Icons.broken_image_outlined,
                            text: 'Could not load QR',
                          ),
                        ),
                ),
                if (qrUrl != null)
                  Positioned(
                    top: SizeConfig.scale(8),
                    right: SizeConfig.scale(8),
                    child: Container(
                      width: SizeConfig.scale(34),
                      height: SizeConfig.scale(34),
                      decoration: BoxDecoration(
                        color: kSubPrimary,
                        borderRadius: BorderRadius.circular(SizeConfig.scale(10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: SizeConfig.scale(22),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (qrUrl != null) ...[
            SizedBox(height: SizeConfig.scale(8)),
            Text(
              'Tap the QR to enlarge for scanning',
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(11),
                color: AppColors.grey2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (note != null && note!.isNotEmpty) ...[
            SizedBox(height: SizeConfig.scale(14)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.scale(12),
                vertical: SizeConfig.scale(10),
              ),
              decoration: BoxDecoration(
                color: AppColors.white2,
                borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: SizeConfig.scale(16), color: kSubPrimary),
                  SizedBox(width: SizeConfig.scale(8)),
                  Expanded(
                    child: Text(
                      note!,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(12),
                        color: AppColors.blue2,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
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
}

class _QrPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;
  const _QrPlaceholder({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: SizeConfig.scale(40), color: AppColors.grey2),
          SizedBox(height: SizeConfig.scale(8)),
          Text(
            text,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(12),
              color: AppColors.grey2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen, pinch-to-zoom view of the payment QR on a white background, so
/// it's large and high-contrast enough for another phone to scan.
class _FullScreenQrViewer extends StatelessWidget {
  final String qrUrl;
  const _FullScreenQrViewer({required this.qrUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan to pay',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.scale(16)),
              child: Image.network(
                qrUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: kSubPrimary),
                  );
                },
                errorBuilder: (context, error, stack) => const _QrPlaceholder(
                  icon: Icons.broken_image_outlined,
                  text: 'Could not load QR',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProofPicker extends StatelessWidget {
  final File? image;
  final bool uploaded;
  final bool isUploading;
  final double progress;
  final VoidCallback? onTap;

  const _ProofPicker({
    required this.image,
    required this.uploaded,
    required this.isUploading,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(SizeConfig.scale(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
          border: Border.all(
            color: uploaded ? kSubPrimary : AppColors.green14,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: SizeConfig.scale(56),
              height: SizeConfig.scale(56),
              decoration: BoxDecoration(
                color: AppColors.white2,
                borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
              ),
              clipBehavior: Clip.antiAlias,
              child: image != null
                  ? Image.file(image!, fit: BoxFit.cover)
                  : Icon(Icons.add_a_photo_outlined,
                      color: kSubPrimary, size: SizeConfig.scale(24)),
            ),
            SizedBox(width: SizeConfig.scale(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUploading
                        ? 'Uploading…'
                        : uploaded
                            ? 'Screenshot uploaded'
                            : image != null
                                ? 'Tap to re-select'
                                : 'Tap to add screenshot',
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(14),
                      fontWeight: FontWeight.w700,
                      color: uploaded
                          ? kSubPrimary
                          : AppColors.blue2,
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(4)),
                  if (isUploading)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(SizeConfig.scale(6)),
                      child: LinearProgressIndicator(
                        value: progress == 0 ? null : progress,
                        minHeight: SizeConfig.scale(5),
                        backgroundColor: AppColors.backgroundAlt,
                        valueColor: const AlwaysStoppedAnimation(kSubMid),
                      ),
                    )
                  else
                    Text(
                      uploaded
                          ? 'Ready to submit'
                          : 'JPG / PNG of your payment',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(11),
                        color: AppColors.grey2,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              uploaded ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: uploaded ? kSubPrimary : AppColors.grey2,
              size: SizeConfig.scale(22),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled || isLoading ? 1 : 0.5,
      child: Material(
        color: kSubPrimary,
        borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
          onTap: enabled ? onTap : null,
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
                : Text(
                    'Submit for verification',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: SizeConfig.scaledFontSize(16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
