// test/test_step3_golden_truth.dart
// ============================================================================
// CostReveal: M4 QA — Excel Golden Truth Cross-Verification
// ============================================================================
// PURPOSE:
//   Print every value needed to manually build the Excel =IRR() golden
//   truth sheet, and run an INDEPENDENT manual IRR calculation (separate
//   from MathEngine's bisection code) as a second cross-check layer.
//
// PROTOCOL: IRR() ONLY. XIRR DROPPED per Architect decision.
// TOLERANCE: ±0.05% between Dart engine and Excel/manual IRR.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import '../lib/models/loan_terms.dart';
import '../lib/engine/math_engine.dart';

void main() {
  final engine = MathEngine();

  test('GOLDEN TRUTH A: Principal=50000, Rate=12%, Fee=2000, Insurance=150',
      () {
    final terms = ConfirmedLoanTerms.fromValues(
      principal_amount: 50000.0,
      tenure_months: 12,
      advertised_flat_rate: 12.0,
      upfront_processing_fee: 2000.0,
      monthly_insurance_premium: 150.0,
    );

    final result = engine.exposeTheTruth(terms);

    print('\n');
    print('======================================================');
    print('  GOLDEN TRUTH TEST A — EXCEL SETUP VALUES');
    print('======================================================');
    print('  Paste these into Excel column A:');
    print('  A1:  -${result.net_disbursed_amount.toStringAsFixed(2)}');
    for (int i = 1; i <= terms.tenure_months; i++) {
      print(
        '  A${i + 1}:  ${result.actual_monthly_outflow.toStringAsFixed(2)}',
      );
    }
    print('');
    print('  In B1, type:  =IRR(A1:A${terms.tenure_months + 1})');
    print('  In B2, type:  =B1*12*100   <-- This is Excel True APR');
    print('');
    print('  DART ENGINE OUTPUT:');
    print('    monthly_irr:  ${result.monthly_irr.toStringAsFixed(4)}%');
    print('    true_apr:     ${result.true_apr.toStringAsFixed(4)}%');
    print('======================================================\n');

    // ── INDEPENDENT MANUAL IRR CROSS-CHECK (bisection, written fresh) ──────
    final independentMonthlyIRR = _independentIRR(result.monthly_cash_flows);
    final independentAPR = independentMonthlyIRR * 12 * 100;

    print('  INDEPENDENT MANUAL IRR CROSS-CHECK (not using MathEngine code):');
    print('    manual_monthly_irr: ${(independentMonthlyIRR * 100).toStringAsFixed(4)}%');
    print('    manual_apr:         ${independentAPR.toStringAsFixed(4)}%');
    print('======================================================\n');

    // Sanity: engine's own APR must match independent calc within tolerance
    expect(
      (result.true_apr - independentAPR).abs() < 0.05,
      true,
      reason:
          'Engine true_apr must match independent IRR calc within ±0.05%',
    );

    // Known expected value (pre-verified mathematically for this exact case)
    expect(
      result.true_apr,
      closeTo(35.77, 0.1),
      reason: 'True APR for Test A must be approximately 35.77%',
    );
  });

  test('GOLDEN TRUTH B: Principal=30000, Rate=10%, Fee=0, Insurance=0', () {
    final terms = ConfirmedLoanTerms.fromValues(
      principal_amount: 30000.0,
      tenure_months: 6,
      advertised_flat_rate: 10.0,
      upfront_processing_fee: 0.0,
      monthly_insurance_premium: 0.0,
    );

    final result = engine.exposeTheTruth(terms);

    print('\n');
    print('======================================================');
    print('  GOLDEN TRUTH TEST B — EXCEL SETUP VALUES');
    print('======================================================');
    print('  Paste these into Excel column A:');
    print('  A1:  -${result.net_disbursed_amount.toStringAsFixed(2)}');
    for (int i = 1; i <= terms.tenure_months; i++) {
      print(
        '  A${i + 1}:  ${result.actual_monthly_outflow.toStringAsFixed(2)}',
      );
    }
    print('');
    print('  In B1, type:  =IRR(A1:A${terms.tenure_months + 1})');
    print('  In B2, type:  =B1*12*100   <-- This is Excel True APR');
    print('');
    print('  DART ENGINE OUTPUT:');
    print('    monthly_irr:  ${result.monthly_irr.toStringAsFixed(4)}%');
    print('    true_apr:     ${result.true_apr.toStringAsFixed(4)}%');
    print('======================================================\n');

    final independentMonthlyIRR = _independentIRR(result.monthly_cash_flows);
    final independentAPR = independentMonthlyIRR * 12 * 100;

    print('  INDEPENDENT MANUAL IRR CROSS-CHECK (not using MathEngine code):');
    print('    manual_monthly_irr: ${(independentMonthlyIRR * 100).toStringAsFixed(4)}%');
    print('    manual_apr:         ${independentAPR.toStringAsFixed(4)}%');
    print('======================================================\n');

    expect(
      (result.true_apr - independentAPR).abs() < 0.05,
      true,
      reason:
          'Engine true_apr must match independent IRR calc within ±0.05%',
    );

    expect(
      result.true_apr,
      closeTo(16.94, 0.1),
      reason: 'True APR for Test B must be approximately 16.94%',
    );
  });
}

// ============================================================================
// INDEPENDENT IRR IMPLEMENTATION
// ============================================================================
// This is a SEPARATE, freshly-written Newton's-method-free bisection solver.
// It does NOT call MathEngine's private methods. It exists purely as a
// second, independent mathematical witness to cross-check the engine's
// result — the same principle as Excel's =IRR(), implemented in Dart.
// ============================================================================
double _independentIRR(List<double> cashFlows) {
  double low = -0.99;
  double high = 5.0;

  double npvAt(double rate) {
    double npv = 0.0;
    for (int t = 0; t < cashFlows.length; t++) {
      npv += cashFlows[t] / _powManual(1 + rate, t);
    }
    return npv;
  }

  for (int i = 0; i < 200; i++) {
    final mid = (low + high) / 2;
    final npv = npvAt(mid);
    if (npv.abs() < 0.0001) return mid;
    if (npv > 0) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return (low + high) / 2;
}

double _powManual(double base, int exponent) {
  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
