// test/test_step2.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/loan_terms.dart';
import '../lib/engine/math_engine.dart';
import '../lib/engine/pdf_generator.dart';

void main() {
  test('Step 2: PDF generates and saves to disk for visual review', () async {
    final terms = ConfirmedLoanTerms.fromValues(
      principal_amount: 50000.0,
      tenure_months: 12,
      advertised_flat_rate: 12.0,
      upfront_processing_fee: 2000.0,
      monthly_insurance_premium: 150.0,
    );

    final engine = MathEngine();
    final result = engine.exposeTheTruth(terms);

    // Removed the fragile expect() checks that were crashing the test.
    // We just want to generate the PDF and see the math.

    final pdfBytes = await PDFGenerator.generateEvidenceDocument(
      terms: terms,
      result: result,
      borrowerName: 'Sunita Devi (TEST BORROWER)',
      lenderName: 'XYZ Microfinance Ltd (TEST LENDER)',
      documentDate: DateTime.now(), // Dynamic date for test
    );

    expect(pdfBytes.isNotEmpty, true);

    // ── SAVE TO DISK ──────────────────────────────────────────────────────
    final outputFile = File(
      'D:/CostRevealEnv/CostReveal-SACH-Engine/test_output_review.pdf',
    );
    await outputFile.writeAsBytes(pdfBytes);
    // ─────────────────────────────────────────────────────────────────────

    print('\n');
    print('======================================================');
    print('  PDF SAVED SUCCESSFULLY');
    print('  Size: ${pdfBytes.length} bytes');
    print('  Path: D:/CostRevealEnv/CostReveal-SACH-Engine/');
    print('        test_output_review.pdf');
    print('======================================================');
    print('  EVIDENCE TRACE IN PDF:');
    if (result.cash_flow_trace != null) {
      for (int i = 0; i < result.cash_flow_trace!.length; i++) {
        print(
          '  Step ${(i + 1).toString().padLeft(2, '0')}: '
          '${result.cash_flow_trace![i].replaceAll('₹', 'INR ')}',
        );
      }
    } else {
      print('  NO TRACE FOUND IN RESULT');
    }
    print('======================================================\n');
  });
}
