import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../state/app_state.dart';
import '../engine/pdf_generator.dart';
import '../models/loan_terms.dart';
import '../utils/formatters.dart';

class RbiDraftScreen extends StatelessWidget {
  const RbiDraftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppProvider>();
    final terms = appState.confirmedTerms;
    final result = appState.calculationResult;

    final formatAmt = (double? amt) => amt == null ? '[auto-filled]' : Formatters.formatAmountWithoutSymbol(amt);
    final formatPct = (double? pct) => pct == null ? '[X]' : pct.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    final formatMonths = (int? m) => m == null ? '[X]' : m.toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Draft Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDraftBanner(),
            const SizedBox(height: 32),
            _buildReportHeader(),
            const SizedBox(height: 24),
            _buildCaseInfo(),
            const SizedBox(height: 24),
            _buildLoanTerms(terms, formatAmt, formatPct, formatMonths),
            const SizedBox(height: 24),
            _buildWarningSection(terms, result, formatAmt, formatPct),
            const SizedBox(height: 24),
            _buildCalculationTrace(result),
            const SizedBox(height: 32),
            _buildNextSteps(),
            const SizedBox(height: 32),
            _buildSource(),
            const SizedBox(height: 48),
            _buildShareButton(context, terms, result),
            const SizedBox(height: 12),
            _buildStartOverButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
      ),
      child: Column(
        children: const [
          Text(
            'DRAFT ONLY — SUBMIT VIA RBI OMS PORTAL',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'https://cms.rbi.org.in',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFDC2626),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOAN COST ANALYSIS REPORT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Evidence Document for Regulatory Complaint',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCaseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CASE INFORMATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Document Date:', DateTime.now().toLocal().toString().split(' ')[0]),
          const SizedBox(height: 6),
          _infoRow('Analysis Tool:', 'CostReveal v1.0'),
          const SizedBox(height: 6),
          _infoRow('Data Source:', 'Human-Verified'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanTerms(
    ConfirmedLoanTerms? terms,
    String Function(double?) formatAmt,
    String Function(double?) formatPct,
    String Function(int?) formatMonths,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOAN TERMS (AS ADVERTISED)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _tableHeader('Term', 'Value'),
              _tableRow('Principal Amount', 'INR ${formatAmt(terms?.principal_amount)}'),
              _tableRow('Loan Tenure', '${formatMonths(terms?.tenure_months)} months'),
              _tableRow('Advertised Interest Rate', '${formatPct(terms?.advertised_flat_rate)}% p.a.'),
              _tableRow('Upfront Processing Fee', 'INR ${formatAmt(terms?.upfront_processing_fee)}'),
              _tableRow('Monthly Insurance', 'INR ${formatAmt(terms?.monthly_insurance_premium)}', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningSection(
    ConfirmedLoanTerms? terms,
    CalculationResult? result,
    String Function(double?) formatAmt,
    String Function(double?) formatPct,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFEF4444)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: const Text(
              'WARNING: HIGH EFFECTIVE COST',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _warningTableHeader(),
                const SizedBox(height: 8),
                _warningTableRow(
                  'Annual Interest Rate',
                  '${formatPct(terms?.advertised_flat_rate)}%',
                  '${formatPct(result?.true_apr)}%',
                ),
                _warningTableRow(
                  'Amount Received',
                  'INR ${formatAmt(terms?.principal_amount)}',
                  'INR ${formatAmt(result?.net_disbursed_amount)}',
                ),
                _warningTableRow(
                  'Monthly Payment',
                  '(Not Disclosed)',
                  'INR ${formatAmt(result?.actual_monthly_outflow)}',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationTrace(CalculationResult? result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CALCULATION TRACE\nMATHEMATICAL EVIDENCE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
            letterSpacing: 1.0,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _renderTraceItems(result),
        ),
      ],
    );
  }

  Widget _renderTraceItems(CalculationResult? result) {
    if (result == null || result.cash_flow_trace == null || result.cash_flow_trace!.isEmpty) {
      return const Text(
        'Calculation trace unavailable.',
        style: TextStyle(fontFamily: 'monospace', color: Colors.black54),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: result.cash_flow_trace!.asMap().entries.map((entry) {
        final stepNum = (entry.key + 1).toString().padLeft(2, '0');
        final text = entry.value.replaceAll('₹', 'INR ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Step $stepNum -> $text',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NEXT STEPS FOR COMPLAINT SUBMISSION',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        _stepRow('1', 'Visit the RBI complaint portal'),
        _stepRow('2', 'File complaint under the relevant category'),
        _stepRow('3', 'Upload this document as supporting evidence'),
        _stepRow('4', 'Quote the calculated APR figure when filing'),
      ],
    );
  }

  Widget _stepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSource() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade400, width: 4)),
      ),
      child: const Text(
        'Cost analysis uses a deterministic cash-flow calculation. RBI KFS guidance requires disclosure of APR and associated charges. Verify the lender\'s KFS and applicable RBI requirements before submitting a complaint.\n\nSource: RBI - Key Facts Statement (KFS) for Loans & Advances, RBI/2026-27/18, April 15, 2026.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _tableHeader(String col1, String col2) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              col1,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              col2,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningTableHeader() {
    return Row(
      children: const [
        Expanded(
          flex: 2,
          child: Text(
            'Metric',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Advertised',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'ACTUAL TRUTH',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _warningTableRow(String metric, String advertised, String actual, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              metric,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              advertised,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              actual,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, ConfirmedLoanTerms? terms, CalculationResult? result) {
    return ElevatedButton.icon(
      onPressed: () async {
        if (terms == null || result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot share: Report data is incomplete.')),
          );
          return;
        }
        
        try {
          final pdfBytes = await PDFGenerator.generateEvidenceDocument(
            terms: terms,
            result: result,
          );
          
          final xFile = XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: 'CostReveal_Report.pdf'); 
          await Share.shareXFiles([xFile], subject: 'CostReveal - Loan Transparency Report', text: 'Please find attached the Loan Transparency Report.');
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to share document: ')),
            );
          }
        }
      },
      icon: const Icon(Icons.share),
      label: const Text('WhatsApp / Email'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
      ),
    );
  }

  Widget _buildStartOverButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text('Start Over'),
    );
  }
}
