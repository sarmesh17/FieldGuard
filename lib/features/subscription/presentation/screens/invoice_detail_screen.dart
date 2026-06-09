import 'package:fieldguard/core/theme/app_colors.dart';
import 'package:fieldguard/features/subscription/data/dto/invoice.dart';
import 'package:fieldguard/features/subscription/presentation/widgets/invoice_pdf.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Printable invoice. Renders the invoice as a real PDF and shows it in
/// [PdfPreview], whose toolbar provides native print + share + save-as-PDF — so
/// no server-side PDF is needed.
class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.green,
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: PdfPreview(
        build: (format) => buildInvoicePdf(invoice),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: '${invoice.invoiceNumber}.pdf',
        loadingWidget:
            const Center(child: CircularProgressIndicator(color: AppColors.green)),
      ),
    );
  }
}
