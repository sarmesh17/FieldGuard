part of 'task_detail_screen.dart';

// ─── Navigate FAB ─────────────────────────────────────────────────────────────

/// Switches to the Routes tab to draw the driving route to this task's shop.
/// White pill so it reads as secondary to the brand-coloured Update FAB above
/// which it sits.
class _NavigateFab extends StatelessWidget {
  final VoidCallback onTap;

  const _NavigateFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.navigation_rounded, color: _kBrand, size: 18),
              SizedBox(width: 8),
              Text(
                'Navigate',
                style: TextStyle(
                  color: _kBrand,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Collect Payment FAB ──────────────────────────────────────────────────────

/// Amber FAB so it reads as a distinct action from the white Navigate and
/// brand-green Update buttons it sits with. Same `field_guard_re` colour
/// language so designs stay consistent across the two apps.
class _CollectPaymentFab extends StatelessWidget {
  final VoidCallback onTap;

  const _CollectPaymentFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xffB45309);
    return Material(
      color: amber,
      borderRadius: BorderRadius.circular(30),
      elevation: 6,
      shadowColor: amber.withValues(alpha: 0.40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payments_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Collect Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Update FAB ───────────────────────────────────────────────────────────────

class _UpdateFab extends StatelessWidget {
  final VoidCallback onTap;

  const _UpdateFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBrand,
      borderRadius: BorderRadius.circular(30),
      elevation: 6,
      shadowColor: _kBrand.withValues(alpha: 0.40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Update',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Update Task Sheet ────────────────────────────────────────────────────────

class _UpdateTaskSheet extends ConsumerStatefulWidget {
  final TaskData task;

  const _UpdateTaskSheet({required this.task});

  @override
  ConsumerState<_UpdateTaskSheet> createState() => _UpdateTaskSheetState();
}

class _UpdateTaskSheetState extends ConsumerState<_UpdateTaskSheet> {
  late String _selectedStatus;
  CancelReason? _cancelReason;
  final _changeReasonCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String? _imagePath;
  String? _imageKey;
  UploadStatus _uploadStatus = UploadStatus.idle;
  double _uploadProgress = 0.0;
  bool _submitting = false;
  String? _errorMessage;

  late final ImageUploadService _uploadService;

  static const _statuses = [
    ('PENDING', 'Pending', Color(0xffF59E0B)),
    ('IN_PROGRESS', 'In Progress', Color(0xff3B82F6)),
    ('COMPLETED', 'Completed', Color(0xff22C55E)),
    ('CANCELLED', 'Cancelled', Color(0xff6B7280)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.task.status.toUpperCase();
    _remarksCtrl.text = widget.task.remarks ?? '';
    _uploadService = ImageUploadService(DioClient.createDio());
  }

  @override
  void dispose() {
    _changeReasonCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _onStatusTap(String status) {
    _changeReasonCtrl.clear();
    setState(() {
      _selectedStatus = status;
      _cancelReason = null;
      _imagePath = null;
      _imageKey = null;
      _uploadStatus = UploadStatus.idle;
      _errorMessage = null;
    });
  }

  void _onReasonTap(CancelReason reason) {
    setState(() {
      _cancelReason = reason;
      _imagePath = null;
      _imageKey = null;
      _uploadStatus = UploadStatus.idle;
      _errorMessage = null;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    setState(() {
      _imagePath = path;
      _imageKey = null;
      _uploadStatus = UploadStatus.uploading;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
    try {
      final res = await _uploadService.upload(
        filePath: path,
        category: 'cancel',
        entityId: widget.task.id,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      setState(() {
        _imageKey = res.imageKey;
        _uploadStatus = UploadStatus.done;
      });
    } catch (_) {
      setState(() {
        _uploadStatus = UploadStatus.error;
        _errorMessage = 'Image upload failed. Tap to retry.';
      });
    }
  }

  Future<void> _submit() async {
    final isCancelling = _selectedStatus == 'CANCELLED';
    final isReopening = _selectedStatus == 'PENDING' &&
        widget.task.status.toUpperCase() == 'IN_PROGRESS';

    if (isCancelling) {
      final reason = _cancelReason;
      if (reason == null) {
        setState(() => _errorMessage = 'Please select a cancel reason.');
        return;
      }
      if (reason.requiresPhoto && _imageKey == null) {
        setState(() => _errorMessage = 'Please attach a cancel photo.');
        return;
      }
      if (reason.requiresChangeReason &&
          _changeReasonCtrl.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please describe the reason.');
        return;
      }
    }

    if (isReopening && _changeReasonCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide a reason for reopening.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final reason = _cancelReason;

    final request = UpdateTaskRequest(
      status: _selectedStatus,
      remarks: _remarksCtrl.text.trim().isNotEmpty
          ? _remarksCtrl.text.trim()
          : null,
      cancelReason: isCancelling ? reason?.value : null,
      cancelImage:
          (isCancelling && reason != null && reason.requiresPhoto)
              ? _imageKey
              : null,
      changeReason: isCancelling && reason != null && reason.requiresChangeReason
          ? _changeReasonCtrl.text.trim()
          : isReopening
              ? _changeReasonCtrl.text.trim()
              : null,
    );

    final usecase = ref.read(updateTaskUsecaseProvider);
    final result = await usecase(widget.task.id, request);

    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.pop(context, true);
      case Failure(:final exception):
        setState(() {
          _submitting = false;
          _errorMessage = exception.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final isCancelling = _selectedStatus == 'CANCELLED';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + kb),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffE0E4EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kBrand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: _kBrand, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Update Task',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff0D1B2A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Status ──────────────────────────────────────────────────────
            const Text(
              'Status',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0D1B2A)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((s) {
                final (value, label, color) = s;
                final selected = _selectedStatus == value;
                return _Chip(
                  label: label,
                  selected: selected,
                  selectedColor: color,
                  onTap: () => _onStatusTap(value),
                );
              }).toList(),
            ),

            // ── Cancel Reason ────────────────────────────────────────────────
            if (isCancelling) ...[
              const SizedBox(height: 18),
              const Text(
                'Cancel Reason *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff0D1B2A)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CancelReason.values.map((r) {
                  final selected = _cancelReason == r;
                  return _Chip(
                    label: r.chipLabel,
                    selected: selected,
                    selectedColor: const Color(0xffEF4444),
                    onTap: () => _onReasonTap(r),
                  );
                }).toList(),
              ),

              // ── Cancel Photo ─────────────────────────────────────────────
              if (_cancelReason != null &&
                  _cancelReason!.requiresPhoto) ...[
                const SizedBox(height: 18),
                const Text(
                  'Cancel Photo *',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff0D1B2A)),
                ),
                const SizedBox(height: 10),
                _ImagePickerSection(
                  imagePath: _imagePath,
                  uploadStatus: _uploadStatus,
                  uploadProgress: _uploadProgress,
                  onTap: _uploadStatus == UploadStatus.uploading
                      ? null
                      : _pickImage,
                ),
              ],

              // ── Change Reason (OTHER) ────────────────────────────────────
              if (_cancelReason == CancelReason.other) ...[
                const SizedBox(height: 18),
                const Text(
                  'Reason *',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff0D1B2A)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _changeReasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the reason…',
                    hintStyle: const TextStyle(
                        fontSize: 13.5, color: Color(0xffB0B7C3)),
                    filled: true,
                    fillColor: const Color(0xffF2F4F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ],

            // ── Reopen Reason ─────────────────────────────────────────────────
            if (_selectedStatus == 'PENDING' &&
                widget.task.status.toUpperCase() == 'IN_PROGRESS') ...[
              const SizedBox(height: 18),
              const Text(
                'Reason for Reopening *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff0D1B2A)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _changeReasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Why is this task being reopened?',
                  hintStyle: const TextStyle(
                      fontSize: 13.5, color: Color(0xffB0B7C3)),
                  filled: true,
                  fillColor: const Color(0xffF2F4F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ],

            // ── Remarks ──────────────────────────────────────────────────────
            const SizedBox(height: 18),
            const Text(
              'Remarks (optional)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0D1B2A)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _remarksCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any remarks…',
                hintStyle: const TextStyle(
                    fontSize: 13.5, color: Color(0xffB0B7C3)),
                filled: true,
                fillColor: const Color(0xffF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xffEF4444)),
              ),
            ],

            const SizedBox(height: 24),
            // ── Action buttons ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xffE0E4EA)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff6B7280)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBrand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected
              ? selectedColor
              : const Color(0xffF2F4F7),
          border: Border.all(
            color: selected ? selectedColor : const Color(0xffE0E4EA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    selected ? Colors.white : const Color(0xff6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  final String? imagePath;
  final UploadStatus uploadStatus;
  final double uploadProgress;
  final VoidCallback? onTap;

  const _ImagePickerSection({
    required this.imagePath,
    required this.uploadStatus,
    required this.uploadProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: hasImage ? 160 : 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xffF2F4F7),
          border: Border.all(
            color: const Color(0xffE0E4EA),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath!), fit: BoxFit.cover),
                  if (uploadStatus == UploadStatus.uploading)
                    Container(
                      color: Colors.black54,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: uploadProgress,
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(uploadProgress * 100).toInt()}%',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  if (uploadStatus == UploadStatus.done)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xff22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_a_photo_rounded,
                      size: 26, color: Color(0xffB0B7C3)),
                  SizedBox(height: 6),
                  Text(
                    'Attach cancel photo (required)',
                    style: TextStyle(
                        fontSize: 12.5, color: Color(0xff8A94A6)),
                  ),
                ],
              ),
      ),
    );
  }
}

