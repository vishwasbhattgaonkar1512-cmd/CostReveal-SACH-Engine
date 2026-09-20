// lib/engine/pdf_generator.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/loan_terms.dart';
import '../utils/formatters.dart';

class PDFGenerator {
  static Future<Uint8List> generateEvidenceDocument({
    required ConfirmedLoanTerms terms,
    required CalculationResult result,
    String? borrowerName,
    String? lenderName,
    DateTime? documentDate,
  }) async {
    final pdf = pw.Document();
    final date = documentDate ?? DateTime.now();
    
    String formatAmt(double amt) => Formatters.formatAmountWithoutSymbol(amt);
    String formatPct(double pct) => pct.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // DRAFT HEADER
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              color: PdfColors.red,
              child: pw.Column(
                children: [
                  pw.Text(
                    'DRAFT ONLY - REVIEW BEFORE SUBMISSION',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'DRAFT FOR RBI OMBUDSMAN COMPLAINT',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'https://cms.rbi.org.in',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // TITLE
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
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
            ),
            pw.Divider(thickness: 2, color: PdfColors.blue900),

            pw.SizedBox(height: 20),

            // CASE INFO
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.grey100,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CASE INFORMATION',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Document Date: ${_formatDate(date)}', style: const pw.TextStyle(fontSize: 10)),
                  if (borrowerName != null)
                    pw.Text('Borrower: $borrowerName', style: const pw.TextStyle(fontSize: 10)),
                  if (lenderName != null)
                    pw.Text('Lender: $lenderName', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Analysis Tool: CostReveal v1.0', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Data Source: Human-Verified', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // LOAN TERMS
            pw.Text(
              'LOAN TERMS (AS ADVERTISED)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _buildHeaderRow(['Term', 'Value']),
                _buildRow('Principal Amount', 'Rs. ${formatAmt(terms.principal_amount)}'),
                _buildRow('Loan Tenure', '${terms.tenure_months} months'),
                _buildRow('Advertised Interest Rate', '${formatPct(terms.advertised_flat_rate)}%'),
                _buildRow('Upfront Processing Fee', 'Rs. ${formatAmt(terms.upfront_processing_fee)}'),
                _buildRow('Monthly Insurance', 'Rs. ${formatAmt(terms.monthly_insurance_premium)}'),
              ],
            ),

            pw.SizedBox(height: 20),

            // THE SMOKING GUN
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'WARNING: THE SMOKING GUN',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        color: PdfColors.red,
                        child: pw.Text(
                          '${formatPct(result.true_apr / terms.advertised_flat_rate)}x DECEPTION',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 15),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.red, width: 1.5),
                    children: [
                      _buildHeaderRow(['Metric', 'Advertised', 'ACTUAL TRUTH'], isAlert: true),
                      _buildComparisonRow(
                        'Annual Interest Rate',
                        '${formatPct(terms.advertised_flat_rate)}%',
                        '${formatPct(result.true_apr)}%',
                      ),
                      _buildComparisonRow(
                        'Amount Received',
                        'Rs. ${formatAmt(terms.principal_amount)}',
                        'Rs. ${formatAmt(result.net_disbursed_amount)}',
                      ),
                      _buildComparisonRow(
                        'Monthly Payment',
                        '(Not Disclosed)',
                        'Rs. ${formatAmt(result.actual_monthly_outflow)}',
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Cost analysis uses a deterministic cash-flow calculation. RBI KFS guidance requires disclosure of APR and associated charges. Verify the lender\'s KFS and applicable RBI requirements before submitting a complaint.\nSource: RBI — Key Facts Statement (KFS) for Loans & Advances, RBI/2024-25/18, April 15, 2024.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // FINANCIAL BREAKDOWN
            pw.Text(
              'FINANCIAL BREAKDOWN',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _buildHeaderRow(['Description', 'Amount (Rs.)']),
                _buildRow('Principal Amount', formatAmt(terms.principal_amount)),
                _buildRow('Less: Processing Fee', '- ${formatAmt(terms.upfront_processing_fee)}'),
                _buildRow('Net Amount Received', formatAmt(result.net_disbursed_amount), isBold: true),
                _buildRow('', ''),
                _buildRow('Monthly EMI Base', formatAmt(result.actual_monthly_outflow - terms.monthly_insurance_premium)),
                _buildRow('Add: Insurance', '+ ${formatAmt(terms.monthly_insurance_premium)}'),
                _buildRow('Total Monthly Outflow', formatAmt(result.actual_monthly_outflow), isBold: true),
                _buildRow('', ''),
                _buildRow('Total Paid', formatAmt(result.actual_monthly_outflow * terms.tenure_months)),
                _buildRow('Total Hidden Cost', formatAmt(result.total_hidden_cost), isBold: true),
              ],
            ),

            pw.SizedBox(height: 20),

            // HIDDEN COST
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              color: PdfColors.orange50,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'HIDDEN COST ANALYSIS',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Hidden Cost (Dirty Tricks Tax):', style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Rs. ${formatAmt(result.total_hidden_cost)}',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'This extra amount results from three predatory practices:',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('  - TRAP 1: Flat Rate Interest', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('  - TRAP 2: Upfront Fee Deduction', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('  - TRAP 3: Ghost Insurance', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // FOOTER
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 10),
            pw.Text(
              'NEXT STEPS FOR COMPLAINT SUBMISSION',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text('  - Visit: https://cms.rbi.org.in', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('  - File complaint under Loans and Advances', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('  - Upload this document as evidence', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated by CostReveal v1.0 - NGO Field Tool',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.Text(
              'Philosophy: AI reads. Human verifies. Mathematics decides.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

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
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
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

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }
}