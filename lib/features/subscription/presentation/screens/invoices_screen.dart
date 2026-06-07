import 'package:fieldguard/core/theme/app_colors.dart';
import 'package:fieldguard/features/subscription/data/dto/invoice.dart';
import 'package:fieldguard/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fieldguard/features/subscription/presentation/screens/invoice_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kBrand = AppColors.green;

/// Subscription invoices list. Each row → a printable [InvoiceDetailScreen].
class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kBrand,
        title: const Text(
          'Invoices',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBrand)),
        error: (err, _) => _ErrorRetry(
          message: 'Could not load invoices',
          onRetry: () => ref.invalidate(invoicesProvider),
        ),
        data: (invoices) {
          if (invoices.isEmpty) return const _Empty();
          return RefreshIndicator(
            color: _kBrand,
            onRefresh: () async => ref.invalidate(invoicesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: invoices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _InvoiceRow(
                invoice: invoices[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        InvoiceDetailScreen(invoice: invoices[i]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  const _InvoiceRow({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final planLabel = invoice.item.planLabel ?? invoice.item.plan ?? 'Plan';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.grey4),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kBrand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 22, color: _kBrand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        _StatusBadge(invoice: invoice),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      planLabel,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.grey),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _fmtDate(invoice.issuedAt),
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.grey9),
                        ),
                        const Spacer(),
                        Text(
                          _rs(invoice.amountNpr),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _kBrand,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Invoice invoice;
  const _StatusBadge({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final paid = invoice.isPaid;
    final color = paid ? AppColors.green5 : AppColors.orange2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        invoice.status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.grey9),
          SizedBox(height: 12),
          Text(
            'No invoices yet',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'Invoices appear here after a payment is approved.',
            style: TextStyle(fontSize: 12.5, color: AppColors.grey9),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.grey2),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kBrand,
                side: const BorderSide(color: _kBrand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime? d) {
  if (d == null) return '';
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String _rs(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'Rs ${n < 0 ? '-' : ''}$b';
}
