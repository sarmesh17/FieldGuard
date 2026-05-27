import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';

const _kBrand = Color(0xff0E5A3B);
const _kInk = Color(0xff0D1B2A);
const _kMuted = Color(0xff8A94A6);
const _kBg = Color(0xffF2F4F7);

/// Confirmation screen after a successful collection.
///
/// Shows the post-write outstanding snapshot (the authoritative shop state)
/// plus the SMS preview byte-identical to what the shop owner receives.
/// CHEQUE collections show a "Pending settlement" notice instead of an SMS
/// (no SMS goes until the cheque is settled). Shops without a valid contact
/// phone show a "No SMS sent" notice.
class CollectionSuccessScreen extends StatelessWidget {
  final CreateCollectionResponse response;

  const CollectionSuccessScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final c = response.collection;
    final out = response.outstanding;
    final isCheque = c.method == 'CHEQUE';
    final preview = response.smsPreview.isNotEmpty
        ? response.smsPreview.first
        : null;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _kInk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Collection recorded',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _kInk,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SuccessHero(
              amount: c.amount,
              method: c.method,
              status: c.status,
            ),
            const SizedBox(height: 18),
            _OutstandingCard(snapshot: out),
            const SizedBox(height: 14),
            if (preview != null)
              _SmsPreviewCard(preview: preview)
            else if (isCheque)
              const _PendingChequeCard()
            else
              const _NoSmsCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero (amount + method/status badges) ───────────────────────────────────────

class _SuccessHero extends StatelessWidget {
  final String amount;
  final String method;
  final String status;

  const _SuccessHero({
    required this.amount,
    required this.method,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBrand, Color(0xff00874C)],
        ),
        boxShadow: [
          BoxShadow(
            color: _kBrand.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NPR ${_fmtAmount(amount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$method · $status',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Outstanding snapshot ───────────────────────────────────────────────────────

class _OutstandingCard extends StatelessWidget {
  final OutstandingSnapshot snapshot;

  const _OutstandingCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _kBrand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 17, color: _kBrand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OUTSTANDING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      snapshot.shopName,
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _kBrand.withValues(alpha: 0.05),
              border: Border.all(color: _kBrand.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _AmountRow(
                  label: 'Total due',
                  value: snapshot.totalDue,
                  color: _kInk,
                ),
                const Divider(height: 18, color: Color(0xffE9EDF1)),
                _AmountRow(
                  label: 'Collected',
                  value: snapshot.collected,
                  color: _kBrand,
                ),
                const SizedBox(height: 10),
                _AmountRow(
                  label: 'Pending cheques',
                  value: snapshot.pendingCheques,
                  color: const Color(0xffB7791F),
                ),
                const Divider(height: 18, color: Color(0xffE9EDF1)),
                _AmountRow(
                  label: 'Still outstanding',
                  value: snapshot.outstanding,
                  color: const Color(0xffC0392B),
                  emphasised: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool emphasised;

  const _AmountRow({
    required this.label,
    required this.value,
    required this.color,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = emphasised ? 16.0 : 13.5;
    final weight = emphasised ? FontWeight.w800 : FontWeight.w700;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasised ? 13 : 12.5,
              fontWeight: emphasised ? FontWeight.w700 : FontWeight.w600,
              color: emphasised ? _kInk : _kMuted,
            ),
          ),
        ),
        Text(
          'NPR ${_fmtAmount(value)}',
          style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── SMS preview ────────────────────────────────────────────────────────────────

class _SmsPreviewCard extends StatelessWidget {
  final SmsPreview preview;

  const _SmsPreviewCard({required this.preview});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: preview.body));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SMS text copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _kBrand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.sms_outlined,
                    size: 17, color: _kBrand),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'SMS sent to shop',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy SMS',
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded,
                    size: 18, color: _kBrand),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            preview.recipient,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _kBrand,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffF7FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffE5EBE7)),
            ),
            child: Text(
              preview.body,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xff394452),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingChequeCard extends StatelessWidget {
  const _PendingChequeCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xffFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                size: 20, color: Color(0xffB7791F)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cheque recorded',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'The receipt SMS will be sent to the shop once an admin settles this cheque.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff5A6472),
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

class _NoSmsCard extends StatelessWidget {
  const _NoSmsCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xffFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sms_failed_outlined,
                size: 20, color: Color(0xffC0392B)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No SMS sent',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "The shop doesn't have a valid contact phone on file, so no receipt SMS could be sent.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff5A6472),
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

class _CardShell extends StatelessWidget {
  final Widget child;

  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Formats a decimal-string amount with thousands separators + 2dp.
String _fmtAmount(String raw) {
  final n = double.tryParse(raw) ?? 0;
  final fixed = n.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final dec = parts[1];
  // Insert commas every 3 digits from the right.
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '$buf.$dec';
}
