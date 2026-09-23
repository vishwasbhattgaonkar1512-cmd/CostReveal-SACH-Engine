// test_step1.dart
// Run with: dart test_step1.dart
// PURPOSE: Verify cash_flow_trace populates correctly.
// Expected: 9 lines (with fee + insurance), correct format, correct values.

import '../lib/models/loan_terms.dart';
import '../lib/engine/math_engine.dart';

void main() {
  print('======================================================');
  print('STEP 1 VERIFICATION: cash_flow_trace output test');
  print('======================================================\n');

  // ── TEST CASE A: Full dirty tricks (fee + insurance) ──
  print('--- TEST A: Principal=50000, Rate=12%, Fee=2000, Insurance=150 ---\n');

  final termsA = ConfirmedLoanTerms.fromValues(
    principal_amount: 50000.0,
    tenure_months: 12,
    advertised_flat_rate: 12.0,
    upfront_processing_fee: 2000.0,
    monthly_insurance_premium: 150.0,
  );

  final engine = MathEngine();
  final resultA = engine.exposeTheTruth(termsA);

  print('cash_flow_trace has ${resultA.cash_flow_trace.length} lines:');
  print('');
  for (int i = 0; i < resultA.cash_flow_trace.length; i++) {
    print('  [${i}] ${resultA.cash_flow_trace[i]}');
  }

  print('\n--- CORE VALUES (sanity check) ---');
  print('  true_apr:              ${resultA.true_apr.toStringAsFixed(2)}%');
  print('  net_disbursed_amount:  ₹${resultA.net_disbursed_amount.toStringAsFixed(2)}');
  print('  actual_monthly_outflow:₹${resultA.actual_monthly_outflow.toStringAsFixed(2)}');
  print('  total_hidden_cost:     ₹${resultA.total_hidden_cost.toStringAsFixed(2)}');

  // ── ASSERTIONS ──
  print('\n--- ASSERTIONS ---');
  _assert(resultA.cash_flow_trace.length == 9,
      'TEST A: trace should have 9 lines (got ${resultA.cash_flow_trace.length})');
  _assert(resultA.cash_flow_trace[0].contains('Sanctioned'),
      'TEST A: line[0] must contain "Sanctioned"');
  _assert(resultA.cash_flow_trace[0].contains('50000.00'),
      'TEST A: line[0] must contain sanctioned amount 50000.00');
  _assert(resultA.cash_flow_trace[1].contains('Processing Fee'),
      'TEST A: line[1] must contain "Processing Fee"');
  _assert(resultA.cash_flow_trace[3].contains('Net Received'),
      'TEST A: line[3] must contain "Net Received"');
  _assert(resultA.cash_flow_trace[3].contains('48000.00'),
      'TEST A: line[3] net received must be 48000.00');
  _assert(resultA.cash_flow_trace[7].contains('True APR'),
      'TEST A: line[7] must contain "True APR"');
  _assert(resultA.cash_flow_trace[8].contains('Total Hidden Cost'),
      'TEST A: line[8] must contain "Total Hidden Cost"');

  // ── TEST CASE B: Clean loan (zero fee, zero insurance) ──
  print('\n\n--- TEST B: Principal=30000, Rate=10%, Fee=0, Insurance=0 ---\n');

  final termsB = ConfirmedLoanTerms.fromValues(
    principal_amount: 30000.0,
    tenure_months: 6,
    advertised_flat_rate: 10.0,
    upfront_processing_fee: 0.0,
    monthly_insurance_premium: 0.0,
  );

  final resultB = engine.exposeTheTruth(termsB);

  print('cash_flow_trace has ${resultB.cash_flow_trace.length} lines:');
  print('');
  for (int i = 0; i < resultB.cash_flow_trace.length; i++) {
    print('  [${i}] ${resultB.cash_flow_trace[i]}');
  }

  print('\n--- ASSERTIONS ---');
  _assert(resultB.cash_flow_trace.length == 6,
      'TEST B: trace should have 6 lines when fee=0 and insurance=0 (got ${resultB.cash_flow_trace.length})');
  _assert(!resultB.cash_flow_trace.any((s) => s.contains('Processing Fee')),
      'TEST B: "Processing Fee" must NOT appear when fee=0');
  _assert(!resultB.cash_flow_trace.any((s) => s.contains('Insurance')),
      'TEST B: "Insurance" must NOT appear when insurance=0');

  print('\n======================================================');
  print('ALL ASSERTIONS PASSED. Step 1 is complete.');
  print('======================================================');
}

void _assert(bool condition, String message) {
  if (!condition) {
    print('  ❌ FAIL: $message');
  } else {
    print('  ✅ PASS: $message');
  }
}
