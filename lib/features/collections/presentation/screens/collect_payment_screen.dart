import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_request.dart';
import 'package:fieldguard/features/collections/presentation/providers/collection_provider.dart';
import 'package:fieldguard/features/collections/presentation/screens/collection_success_screen.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

const _kBrand = AppColors.green;
const _kBrandLight = AppColors.green;
const _kInk = AppColors.ink2;
const _kMuted = AppColors.grey2;
const _kBg = AppColors.white;

/// Form for `POST /api/v1/collections`. Caller passes the task's shop so the
/// user never picks it — the screen is opened from a specific task. Server
/// expects: shopId, amount (>0, ≤2dp), method (CASH|CHEQUE), and for CHEQUE
/// the chequeNumber (required), chequeBank (optional), chequeDate (optional).
class CollectPaymentScreen extends ConsumerStatefulWidget {
  final int shopId;
  final String shopName;

  /// Task this collection is being made under (optional). Passed straight to
  /// the API so the task's manager is also notified.
  final int? taskId;

  const CollectPaymentScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    this.taskId,
  });

  @override
  ConsumerState<CollectPaymentScreen> createState() =>
      _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends ConsumerState<CollectPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _chequeNumberCtrl = TextEditingController();
  final _chequeBankCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _onlineRefCtrl = TextEditingController();
  final _onlineProviderOtherCtrl = TextEditingController();
  DateTime? _chequeDate;

  CollectionMethod _method = CollectionMethod.cash;
  // ONLINE provider preset: ESEWA | KHALTI | BANK | OTHER (OTHER → free text).
  String? _onlineProvider;
  // Method visibility by role (server enforces the same; we just hide options
  // that would 403): EMPLOYEE → CASH/CHEQUE, MANAGER → all three,
  // ADMIN → ONLINE only. Resolved once from the JWT role.
  bool _canOnline = false;
  bool _isAdmin = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    final role = (await Session.role())?.toUpperCase();
    if (!mounted) return;
    setState(() {
      _isAdmin = role == 'ADMIN';
      _canOnline = role == 'ADMIN' || role == 'MANAGER';
      // ADMIN can't record CASH/CHEQUE (403), so start them on ONLINE.
      if (_isAdmin) _method = CollectionMethod.online;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _chequeNumberCtrl.dispose();
    _chequeBankCtrl.dispose();
    _notesCtrl.dispose();
    _onlineRefCtrl.dispose();
    _onlineProviderOtherCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickChequeDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _chequeDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _chequeDate = picked);
  }

  String _formatChequeDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_amountCtrl.text.trim());
    final request = CreateCollectionRequest(
      shopId: widget.shopId,
      taskId: widget.taskId,
      amount: amount,
      method: _method,
      chequeNumber: _method == CollectionMethod.cheque
          ? _chequeNumberCtrl.text.trim()
          : null,
      chequeBank: _method == CollectionMethod.cheque &&
              _chequeBankCtrl.text.trim().isNotEmpty
          ? _chequeBankCtrl.text.trim()
          : null,
      chequeDate: _method == CollectionMethod.cheque && _chequeDate != null
          ? _formatChequeDate(_chequeDate!)
          : null,
      onlineProvider: _method == CollectionMethod.online
          ? (_onlineProvider == 'OTHER'
              ? _onlineProviderOtherCtrl.text.trim()
              : _onlineProvider)
          : null,
      onlineRef: _method == CollectionMethod.online &&
              _onlineRefCtrl.text.trim().isNotEmpty
          ? _onlineRefCtrl.text.trim()
          : null,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final usecase = ref.read(recordCollectionUsecaseProvider);
    final result = await usecase(request);

    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        // Replace the form with the success screen so back-nav lands on the
        // task detail, not the empty form.
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CollectionSuccessScreen(response: data),
          ),
        );
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
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kInk, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Collect Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _kInk,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + kb),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShopChip(name: widget.shopName),
              const SizedBox(height: 18),
              const _SectionLabel('Method'),
              const SizedBox(height: 10),
              _MethodToggle(
                value: _method,
                methods: [
                  if (!_isAdmin) CollectionMethod.cash,
                  if (!_isAdmin) CollectionMethod.cheque,
                  if (_canOnline) CollectionMethod.online,
                ],
                onChanged: (m) => setState(() {
                  _method = m;
                  _errorMessage = null;
                }),
              ),
              const SizedBox(height: 22),
              const _SectionLabel('Amount (NPR)'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  // Up to 2 decimal places, digits + optional single dot.
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,12}(\.\d{0,2})?'),
                  ),
                ],
                decoration: _inputDecoration(hint: 'e.g. 1500.50'),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Amount is required';
                  final n = double.tryParse(t);
                  if (n == null) return 'Enter a valid amount';
                  if (n <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              if (_method == CollectionMethod.cheque) ...[
                const SizedBox(height: 22),
                const _SectionLabel('Cheque number *'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _chequeNumberCtrl,
                  maxLength: 50,
                  decoration: _inputDecoration(
                    hint: 'e.g. 100234',
                    counter: '',
                  ),
                  validator: (v) {
                    if (_method != CollectionMethod.cheque) return null;
                    if ((v?.trim() ?? '').isEmpty) {
                      return 'Cheque number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Cheque bank'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _chequeBankCtrl,
                  maxLength: 120,
                  decoration: _inputDecoration(
                    hint: 'e.g. Nepal Bank Ltd',
                    counter: '',
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Cheque date'),
                const SizedBox(height: 10),
                _DateField(
                  date: _chequeDate,
                  formatted: _chequeDate == null
                      ? null
                      : _formatChequeDate(_chequeDate!),
                  onPick: _pickChequeDate,
                  onClear: _chequeDate == null
                      ? null
                      : () => setState(() => _chequeDate = null),
                ),
              ],
              if (_method == CollectionMethod.online) ...[
                const SizedBox(height: 22),
                const _SectionLabel('Provider *'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _onlineProvider,
                  isExpanded: true,
                  hint: const Text('Select provider'),
                  decoration: _inputDecoration(hint: 'Select provider'),
                  items: const [
                    DropdownMenuItem(value: 'ESEWA', child: Text('eSewa')),
                    DropdownMenuItem(value: 'KHALTI', child: Text('Khalti')),
                    DropdownMenuItem(
                        value: 'BANK', child: Text('Bank transfer')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() {
                    _onlineProvider = v;
                    _errorMessage = null;
                  }),
                  validator: (v) {
                    if (_method != CollectionMethod.online) return null;
                    if (v == null) return 'Select a provider';
                    return null;
                  },
                ),
                if (_onlineProvider == 'OTHER') ...[
                  const SizedBox(height: 14),
                  const _SectionLabel('Provider name *'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _onlineProviderOtherCtrl,
                    maxLength: 40,
                    decoration:
                        _inputDecoration(hint: 'e.g. IME Pay', counter: ''),
                    validator: (v) {
                      if (_method != CollectionMethod.online ||
                          _onlineProvider != 'OTHER') {
                        return null;
                      }
                      if ((v?.trim() ?? '').isEmpty) {
                        return 'Provider name is required';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 18),
                const _SectionLabel('Transaction reference'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _onlineRefCtrl,
                  maxLength: 100,
                  decoration: _inputDecoration(
                    hint: 'e.g. ESW-7F3K9P2',
                    counter: '',
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const _SectionLabel('Notes (optional)'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                maxLength: 500,
                maxLines: 3,
                decoration: _inputDecoration(
                  hint: 'Anything worth noting…',
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _ErrorBox(message: _errorMessage!),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBrand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
                      : const Text(
                          'Record Collection',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? counter,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 13.5, color: AppColors.grey9),
      filled: true,
      fillColor: Colors.white,
      counterText: counter,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBrand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: _kInk,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _ShopChip extends StatelessWidget {
  final String name;
  const _ShopChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey4),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kBrand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: _kBrand, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COLLECTING FROM',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _kMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
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

class _MethodToggle extends StatelessWidget {
  final CollectionMethod value;
  final List<CollectionMethod> methods;
  final ValueChanged<CollectionMethod> onChanged;

  const _MethodToggle({
    required this.value,
    required this.methods,
    required this.onChanged,
  });

  static (String, IconData) _meta(CollectionMethod m) => switch (m) {
        CollectionMethod.cash => ('Cash', Icons.payments_rounded),
        CollectionMethod.cheque => ('Cheque', Icons.receipt_long_rounded),
        CollectionMethod.online => ('Online', Icons.account_balance_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < methods.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 10));
      final m = methods[i];
      final (label, icon) = _meta(m);
      children.add(
        Expanded(
          child: _MethodChip(
            label: label,
            icon: icon,
            selected: value == m,
            onTap: () => onChanged(m),
          ),
        ),
      );
    }
    return Row(children: children);
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.icon,
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kBrand, _kBrandLight],
                  )
                : null,
            color: selected ? null : Colors.white,
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.grey4,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _kBrand.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : _kBrand,
              ),
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

class _DateField extends StatelessWidget {
  final DateTime? date;
  final String? formatted;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _DateField({
    required this.date,
    required this.formatted,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey4),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 18, color: _kBrand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  formatted ?? 'Pick a date',
                  style: TextStyle(
                    fontSize: 14,
                    color: formatted == null ? AppColors.grey9 : _kInk,
                    fontWeight: formatted == null
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: _kMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.red9,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
