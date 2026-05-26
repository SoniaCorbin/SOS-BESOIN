import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/invoices/models/invoice_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndShareInvoice(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final formatter = DateFormat('d MMMM yyyy', 'fr_CA');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── En-tête ──────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SOS-BESOIN',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'La marketplace d\'urgence',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'FACTURE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.invoiceNumber,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.amber),
              pw.SizedBox(height: 20),

              // ── Statut ───────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  '✓ PAYÉE',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ),
              pw.SizedBox(height: 24),

              // ── Parties ──────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FACTURÉ À',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          invoice.clientName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PRESTATAIRE',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          invoice.providerName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // ── Détails mission ──────────────────────
              pw.Text(
                'DÉTAILS DE LA MISSION',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Service', invoice.requestTitle),
                    pw.SizedBox(height: 8),
                    _buildRow('Catégorie', invoice.requestCategory),
                    pw.SizedBox(height: 8),
                    _buildRow('Date', formatter.format(invoice.createdAt)),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // ── Montants ─────────────────────────────
              pw.Text(
                'DÉTAIL DES MONTANTS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildRow(
                      'Montant total',
                      '${invoice.amount.toStringAsFixed(2)}\$',
                    ),
                    pw.SizedBox(height: 8),
                    _buildRow(
                      'Commission plateforme (10%)',
                      '-${invoice.platformFee.toStringAsFixed(2)}\$',
                      valueColor: PdfColors.red,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    _buildRow(
                      'Montant prestataire',
                      '+${invoice.providerAmount.toStringAsFixed(2)}\$',
                      valueColor: PdfColors.green700,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // ── Pied de page ─────────────────────────
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  '© 2026 SOS-BESOIN · Tous droits réservés',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${invoice.invoiceNumber}.pdf',
    );
  }

  static pw.Widget _buildRow(
      String label,
      String value, {
        PdfColor? valueColor,
        bool isBold = false,
      }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valueColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }
}
