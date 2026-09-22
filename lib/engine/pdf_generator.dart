// lib/engine/pdf_generator.dart
// ============================================================================
// CostReveal: The Dirty Tricks Detector
// PDF Evidence Document Generator (Syntax Fixed & Pagination Locked)
// ============================================================================
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/loan_terms.dart';

class PDFGenerator {
  static Future<Uint8List> generateEvidenceDocument({
    required ConfirmedLoanTerms terms,
    required CalculationResult result,
    String? borrowerName,
    String? lenderName,
    DateTime? documentDate,
  }) async {
    final pdf = pw.Document();

    final String formattedDate = (documentDate ?? DateTime.now()).toString().split(' ')[0];

    // Using explicit return block for MultiPage to guarantee bracket safety
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ================================================================
            // 1. THE RED HEADER
            // ================================================================
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              color: PdfColors.red,
              child: pw.Column(
                children: [
                  pw.Text(
                    'DRAFT ONLY - SUBMIT VIA RBI OMS PORTAL',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'https://cms.rbi.org.in',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'LOAN COST ANALYSIS REPORT',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.Text(
              'Evidence Document for Regulatory Complaint',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey800,
              ),
            ),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 20),

            // ================================================================
            // 2. CASE INFORMATION
            // ================================================================
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.grey100,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CASE INFORMATION', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Document Date: $formattedDate', style: const pw.TextStyle(fontSize: 10)),
                  if (borrowerName != null) pw.Text('Borrower: $borrowerName', style: const pw.TextStyle(fontSize: 10)),
                  if (lenderName != null) pw.Text('Lender: $lenderName', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Analysis Tool: CostReveal v1.0', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Data Source: Human-Verified', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ================================================================
            // 3. LOAN TERMS (AS ADVERTISED)
            // ================================================================
            pw.Text('LOAN TERMS (AS ADVERTISED)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _buildHeaderRow(['Term', 'Value']),
                _buildRow('Principal Amount', 'INR ${terms.principal_amount.toStringAsFixed(2)}'),
                _buildRow('Loan Tenure', '${terms.tenure_months} months'),
                _buildRow('Advertised Interest Rate', '${terms.advertised_flat_rate.toStringAsFixed(2)}%'),
                _buildRow('Upfront Processing Fee', 'INR ${terms.upfront_processing_fee.toStringAsFixed(2)}'),
                _buildRow('Monthly Insurance', 'INR ${terms.monthly_insurance_premium.toStringAsFixed(2)}'),
              ],
            ),
            pw.SizedBox(height: 20),

            // ================================================================
            // 4. RESULTS
            // ================================================================
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(color: PdfColors.red50, border: pw.Border.all(color: PdfColors.red, width: 2)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('WARNING: HIGH EFFECTIVE COST', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                  pw.SizedBox(height: 15),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.red, width: 1.5),
                    children: [
                      _buildHeaderRow(['Metric', 'Advertised', 'ACTUAL TRUTH'], isAlert: true),
                      _buildComparisonRow('Annual Interest Rate', '${terms.advertised_flat_rate.toStringAsFixed(2)}%', '${result.true_apr.toStringAsFixed(2)}%'),
                      _buildComparisonRow('Amount Received', 'INR ${terms.principal_amount.toStringAsFixed(2)}', 'INR ${result.net_disbursed_amount.toStringAsFixed(2)}'),
                      _buildComparisonRow('Monthly Payment', '(Not Disclosed)', 'INR ${result.actual_monthly_outflow.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ================================================================
            // 5. CALCULATION TRACE (MATHEMATICAL EVIDENCE)
            // ================================================================
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue900, width: 1.5)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CALCULATION TRACE (MATHEMATICAL EVIDENCE)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 10),
                  if (result.cash_flow_trace != null && result.cash_flow_trace!.isNotEmpty)
                    ...result.cash_flow_trace!.asMap().entries.map(
                      (entry) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Text("Step ${(entry.key + 1).toString().padLeft(2, '0')} -> ${entry.value.replaceAll('₹', 'INR ')}", style: const pw.TextStyle(fontSize: 10)),
                      ),
                    )
                  else
                    pw.Text('Trace not provided.', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ================================================================
            // 6. NEXT STEPS & RBI FOOTER
            // ================================================================
            pw.Text('NEXT STEPS FOR COMPLAINT SUBMISSION', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('1. Visit: https://cms.rbi.org.in', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('2. File complaint under: Loans and Advances', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('3. Upload this document as supporting evidence', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('4. Quote the Calculated APR figure when filing', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 20),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.grey200,
              child: pw.Text(
                'Source: Reserve Bank of India -- Master Direction on Regulatory \n'
                'Framework for Microfinance Loans & Responsible Business Conduct \n'
                '(Updated 2026).',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ================================================================
  // HELPER METHODS (Safely placed inside the class)
  // ================================================================
  static pw.TableRow _buildHeaderRow(List<String> headers, {bool isAlert = false}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: isAlert ? PdfColors.red : PdfColors.blue900),
      children: headers.map((h) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(h, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      )).toList(),
    );
  }

  static pw.TableRow _buildRow(String label, String value, {bool isBold = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal))),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal))),
      ],
    );
  }

  static pw.TableRow _buildComparisonRow(String label, String advertised, String actual) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(advertised, style: const pw.TextStyle(fontSize: 10))),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(actual, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red900))),
      ],
    );
  }
}