import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/data/dto/settle_collection_request.dart';
import 'package:fieldguard/features/collections/presentation/providers/collection_provider.dart';

const _kBrand = Color(0xff0E5A3B);
const _kInk = Color(0xff0D1B2A);
const _kMuted = Color(0xff8A94A6);

/// Settle sheet for a PENDING cheque. CLEARED / BOUNCED toggle + optional
/// notes. On success pops with the [CreateCollectionResponse] so the caller
/// can show the success screen and refresh the list. Server errors (409
/// over-collection / already-settled / CASH, 400, 403) surface inline verbatim.
class SettleCollectionSheet extends ConsumerStatefulWidget {
  final int collectionId;
  final String amount; // decimal string, for the header
  final String? chequeNumber;

  const SettleCollectionSheet({
    super.key,
    required this.collectionId,
    required this.amount,
    this.chequeNumber,
  });

  @override
  ConsumerState<SettleCollectionSheet> createState() =>
      _SettleCollectionSheetState();
}

class _SettleCollectionSheetState
    extends ConsumerState<SettleCollectionSheet> {
  SettleStatus _status = SettleStatus.cleared;
  final _notesCtrl = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final usecase = ref.read(settleCollectionUsecaseProvider);
    final result = await usecase(
      widget.collectionId,
      SettleCollectionRequest(
        status: _status,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      ),
    );

    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        Navigator.of(context).pop<CreateCollectionResponse>(data);
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + kb),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kBrand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fact_check_rounded,
                      color: _kBrand, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settle Cheque',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _kInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NPR ${widget.amount}'
                        '${widget.chequeNumber != null ? ' · #${widget.chequeNumber}' : ''}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _kMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Outcome',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _OutcomeChip(
                    label: 'Cleared',
                    icon: Icons.check_circle_rounded,
                    color: _kBrand,
                    selected: _status == SettleStatus.cleared,
                    onTap: () => setState(() {
                      _status = SettleStatus.cleared;
                      _errorMessage = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutcomeChip(
                    label: 'Bounced',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xffC0392B),
                    selected: _status == SettleStatus.bounced,
                    onTap: () => setState(() {
                      _status = SettleStatus.bounced;
                      _errorMessage = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _status == SettleStatus.cleared
                  ? 'Counts against the shop\'s due and sends a cleared receipt SMS.'
                  : 'Terminal — the shop\'s due stays intact and no amount is deducted.',
              style: const TextStyle(
                fontSize: 12,
                color: _kMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Notes (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Cleared at bank counter',
                hintStyle:
                    const TextStyle(fontSize: 13.5, color: Color(0xffB0B7C3)),
                filled: true,
                fillColor: const Color(0xffF2F4F7),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 18, color: Color(0xffC0392B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff7A1F1F),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xffE0E4EA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff6B7280),
                      ),
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _status == SettleStatus.cleared
                                ? 'Mark Cleared'
                                : 'Mark Bounced',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
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

class _OutcomeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _OutcomeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? color : Colors.white,
            border: Border.all(
              color: selected ? color : const Color(0xffE0E4EA),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : _kInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
