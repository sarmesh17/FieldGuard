import 'dart:typed_data';

import 'package:fieldguard/features/subscription/data/dto/invoice.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Brand palette mirrored from AppColors (pdf has its own colour type).
final _brand = PdfColor.fromInt(0xFF0E5A3B);
final _ink = PdfColor.fromInt(0xFF111827);
final _muted = PdfColor.fromInt(0xFF667085);
final _amber = PdfColor.fromInt(0xFFF59E0B);

String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// "Rs 1,500" — integer NPR with thousands grouping.
String _rs(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'Rs ${n < 0 ? '-' : ''}$b';
}

/// Builds a printable A4 invoice PDF from [inv]. Pure data → bytes, so it feeds
/// straight into `PdfPreview` / `Printing` (native print + save-as-PDF).
Future<Uint8List> buildInvoicePdf(Invoice inv) async {
  final doc = pw.Document();
  final sellerName =
      inv.seller.displayName.isNotEmpty ? inv.seller.displayName : 'FieldGuard';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      sellerName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _brand,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Field operations, simplified.',
                      style: pw.TextStyle(fontSize: 9, color: _muted),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'TAX INVOICE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      inv.invoiceNumber,
                      style: pw.TextStyle(fontSize: 11, color: _muted),
                    ),
                    pw.Text(
                      'Issued ${_fmtDate(inv.issuedAt)}',
                      style: pw.TextStyle(fontSize: 10, color: _muted),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _party('From', sellerName, inv.seller)),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: _party('Billed to', inv.buyer.displayName, inv.buyer),
                ),
              ],
            ),
            pw.SizedBox(height: 22),
            _itemTable(inv),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _totalRow('Subtotal', _rs(inv.amountNpr)),
                      pw.Divider(color: PdfColors.grey300),
                      _totalRow('Total (NPR)', _rs(inv.amountNpr), bold: true),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                _statusStamp(inv),
                pw.SizedBox(width: 12),
                if (inv.paymentMethod != null &&
                    inv.paymentMethod!.isNotEmpty)
                  pw.Text(
                    'Payment: ${inv.paymentMethod}',
                    style: pw.TextStyle(fontSize: 10, color: _muted),
                  ),
              ],
            ),
            pw.SizedBox(height: 28),
            pw.Divider(color: PdfColors.grey300),
            pw.Text(
              'This is a system-generated invoice and does not require a '
              'signature.',
              style: pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        );
      },
    ),
  );
  return doc.save();
}

pw.Widget _party(String label, String name, InvoiceParty p) {
  final lines = <String>[
    if (p.pan != null && p.pan!.isNotEmpty) 'PAN: ${p.pan}',
    if (p.address != null && p.address!.isNotEmpty) p.address!,
    if (p.contact != null && p.contact!.isNotEmpty) p.contact!,
  ];
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _muted,
          letterSpacing: 0.8,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        name.isEmpty ? '—' : name,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      for (final l in lines) ...[
        pw.SizedBox(height: 2),
        pw.Text(l, style: pw.TextStyle(fontSize: 10, color: _muted)),
      ],
    ],
  );
}

pw.Widget _itemTable(Invoice inv) {
  final period = (inv.item.periodStart != null || inv.item.periodEnd != null)
      ? '${_fmtDate(inv.item.periodStart)} – ${_fmtDate(inv.item.periodEnd)}'
      : '';
  pw.TextStyle th() => pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );
  return pw.Column(
    children: [
      pw.Container(
        color: _brand,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 5, child: pw.Text('Description', style: th())),
            pw.Expanded(
              flex: 2,
              child: pw.Text('Months',
                  style: th(), textAlign: pw.TextAlign.center),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text('Amount',
                  style: th(), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    inv.item.description,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  if (period.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Period: $period',
                      style: pw.TextStyle(fontSize: 9, color: _muted),
                    ),
                  ],
                ],
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                '${inv.item.months}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 11, color: _ink),
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                _rs(inv.amountNpr),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 11, color: _ink),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _totalRow(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: bold ? 12 : 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: bold ? _ink : _muted,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: bold ? 13 : 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: bold ? _brand : _ink,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _statusStamp(Invoice inv) {
  final color = inv.isPaid ? _brand : _amber;
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: color, width: 1.5),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Text(
      inv.status.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: color,
        letterSpacing: 2,
      ),
    ),
  );
}
