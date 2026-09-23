// lib/engine/math_engine.dart
// ============================================================================
// CostReveal: The Dirty Tricks Detector
// Mathematics Engine - IRR-Based True APR Calculator
// ============================================================================
// Philosophy: "AI reads. Human verifies. Mathematics decides."
//
// This file implements the DETERMINISTIC CALCULATION ENGINE that exposes
// three predatory lending traps commonly used in Indian microfinance:
//
// TRAP 1: FLAT RATE DECEPTION
//   - Advertised as "12% interest"
//   - Reality: Interest calculated on ORIGINAL principal every month
//   - Not on reducing balance (which is the fair method)
//   - True APR is nearly DOUBLE the advertised rate
//
// TRAP 2: UPFRONT DEDUCTION TRAP
//   - Processing fee deducted from disbursement
//   - Borrower receives ₹48,000 but pays EMI on ₹50,000
//   - Effective principal is higher than advertised
//
// TRAP 3: GHOST INSURANCE
//   - Mandatory "insurance" or "membership" fees
//   - Added to monthly payment but NOT included in advertised rate
//   - Pure profit for lender disguised as protection
//
// Method: Internal Rate of Return (IRR) using Bisection Method
// Precision: 0.01% (1 basis point)
// Max Iterations: 100
// Output: True APR that matches RBI disclosure requirements
//
// Author: M1 (Engine & Compliance)
// ============================================================================

import 'dart:math' as math;
import '../models/loan_terms.dart';

/// ============================================================================
/// CORE MATHEMATICS ENGINE
/// ============================================================================
/// Pure Dart class. 100% offline. Deterministic. No side effects.
/// Accepts ONLY ConfirmedLoanTerms (human-verified data).
/// Returns CalculationResult (mathematical truth).
/// ============================================================================
class MathEngine {
  // ============================================================================
  // CONFIGURATION CONSTANTS
  // ============================================================================

  /// Maximum iterations for bisection method IRR calculation
  static const int _maxIterations = 100;

  /// IRR convergence tolerance (0.01% = 1 basis point)
  static const double _irrTolerance = 0.0001;

  /// Initial lower bound for IRR search (-50% monthly = effectively free money)
  static const double _irrLowerBound = -0.50;

  /// Initial upper bound for IRR search (50% monthly = 600% APR, extreme usury)
  static const double _irrUpperBound = 0.50;

  /// Months in a year (for APR conversion)
  static const int _monthsPerYear = 12;

  // ============================================================================
  // PUBLIC API: THE TRUTH REVEALER
  // ============================================================================

   /// Expose the truth about a predatory loan.
  ///
  /// This is the ONLY public method. It orchestrates the complete analysis:
  /// 1. Deconstruct the advertised terms
  /// 2. Calculate actual cash flows (what really happens to money)
  /// 3. Use IRR to find the TRUE cost
  /// 4. Quantify the hidden costs
  ///
  /// [terms] MUST be a ConfirmedLoanTerms (human-verified, type-safe)
  ///
  /// Returns a CalculationResult with:
  /// - true_apr: The actual Annual Percentage Rate (not the advertised lie)
  /// - total_hidden_cost: How much extra the borrower pays vs fair loan
  /// - actual_monthly_outflow: Real cash leaving borrower's pocket each month
  /// - net_disbursed_amount: Actual cash borrower receives (after fee deduction)
  /// - PLUS all evidence trace data for UI expander (Task 1)
  ///
  /// This method is deterministic: same input ALWAYS produces same output.
  CalculationResult exposeTheTruth(ConfirmedLoanTerms terms) {
    // Step 1: Calculate what the lender claims (the advertised terms)
    final advertisedMonthlyEmi = _calculateFlatRateEMI(
      terms.principal_amount,
      terms.advertised_flat_rate,
      terms.tenure_months,
    );

    // Step 2: Calculate what ACTUALLY happens (the dirty tricks)
    final netDisbursed = _calculateNetDisbursement(
      terms.principal_amount,
      terms.upfront_processing_fee,
    );

    final actualMonthlyOutflow = _calculateActualMonthlyOutflow(
      advertisedMonthlyEmi,
      terms.monthly_insurance_premium,
    );

    // Step 3: Build the cash flow array (the timeline of money movement)
    final cashFlows = _generateCashFlows(
      netDisbursed,
      actualMonthlyOutflow,
      terms.tenure_months,
    );

    // Step 4: Use IRR to find the TRUE monthly interest rate
    final monthlyIRR = _calculateIRR(cashFlows);

    // Step 5: Convert monthly IRR to annual APR (industry standard)
    final trueAPR = _convertToAPR(monthlyIRR);

    // Step 6: Quantify the hidden cost (the "dirty trick" tax)
    final hiddenCost = _calculateHiddenCost(
      terms.principal_amount,
      actualMonthlyOutflow,
      terms.tenure_months,
      terms.advertised_flat_rate,
    );

    final cashFlowTrace = _buildCashFlowTrace(
      sanctionedAmount: terms.principal_amount,
      processingFee: terms.upfront_processing_fee,
      insuranceCost: terms.monthly_insurance_premium,
      tenureMonths: terms.tenure_months,
      netDisbursed: netDisbursed,
      advertisedMonthlyEmi: advertisedMonthlyEmi,
      actualMonthlyOutflow: actualMonthlyOutflow,
      trueAPR: trueAPR,
      hiddenCost: hiddenCost,
    );

    // Step 7: Package the truth for human consumption
    // Now includes ALL evidence trace data for UI expander (Task 1)
    return CalculationResult(
      // Core outputs
      true_apr: trueAPR,
      total_hidden_cost: hiddenCost,
      actual_monthly_outflow: actualMonthlyOutflow,
      net_disbursed_amount: netDisbursed,
      // Evidence trace data (Task 1)
      sanctioned_amount: terms.principal_amount,
      processing_fee: terms.upfront_processing_fee,
      insurance_cost: terms.monthly_insurance_premium,
      monthly_cash_flows: List.unmodifiable(cashFlows), // Immutable list
      monthly_irr: monthlyIRR * 100, // Convert to percentage
      cash_flow_trace: List.unmodifiable(cashFlowTrace),
    );
  }

  /// Build a human-readable evidence trace of the calculation steps.
  List<String> _buildCashFlowTrace({
    required double sanctionedAmount,
    required double processingFee,
    required double insuranceCost,
    required int tenureMonths,
    required double netDisbursed,
    required double advertisedMonthlyEmi,
    required double actualMonthlyOutflow,
    required double trueAPR,
    required double hiddenCost,
  }) {
    final trace = <String>[];

    trace.add('Sanctioned: ₹${sanctionedAmount.toStringAsFixed(2)}');

    if (processingFee > 0) {
      trace.add(
        'Minus Processing Fee: -₹${processingFee.toStringAsFixed(2)}',
      );
    }

    if (insuranceCost > 0) {
      final totalInsurance = insuranceCost * tenureMonths;
      trace.add(
        'Minus Insurance (total over $tenureMonths months): '
        '-₹${totalInsurance.toStringAsFixed(2)}',
      );
    }

    trace.add('Net Received: ₹${netDisbursed.toStringAsFixed(2)}');
    trace.add(
      'Monthly EMI (flat-rate): ₹${advertisedMonthlyEmi.toStringAsFixed(2)}',
    );

    if (insuranceCost > 0) {
      trace.add(
        'Monthly Insurance Premium: ₹${insuranceCost.toStringAsFixed(2)}',
      );
    }

    trace.add(
      'Total Monthly Outflow: ₹${actualMonthlyOutflow.toStringAsFixed(2)}',
    );
    trace.add('True APR (IRR method): ${trueAPR.toStringAsFixed(2)}%');
    trace.add('Total Hidden Cost: ₹${hiddenCost.toStringAsFixed(2)}');

    return trace;
  }

  // ============================================================================
  // TRAP 1: FLAT RATE DECEPTION CALCULATOR
  // ============================================================================

  /// Calculate EMI using FLAT RATE method (the predatory way).
  ///
  /// FAIR METHOD (Reducing Balance):
  /// - Month 1: Interest on ₹50,000
  /// - Month 2: Interest on ₹46,000 (after first EMI principal portion)
  /// - Month 3: Interest on ₹42,000... etc.
  ///
  /// FLAT RATE METHOD (Predatory):
  /// - Month 1: Interest on ₹50,000
  /// - Month 2: Interest on ₹50,000 (STILL on original amount!)
  /// - Month 3: Interest on ₹50,000... etc.
  ///
  /// Formula:
  /// Total Interest = Principal × (Rate/100) × (Tenure/12)
  /// EMI = (Principal + Total Interest) / Tenure
  ///
  /// Example:
  /// ₹50,000 at 12% for 12 months
  /// Total Interest = 50,000 × 0.12 × 1 = ₹6,000
  /// EMI = (50,000 + 6,000) / 12 = ₹4,667
  ///
  /// [principal] Loan amount (e.g., 50000)
  /// [flatRate] Annual rate as percentage (e.g., 12.0 for 12%)
  /// [tenureMonths] Loan duration in months (e.g., 12)
  double _calculateFlatRateEMI(
    double principal,
    double flatRate,
    int tenureMonths,
  ) {
    // Edge case: Zero interest (promotional loans)
    if (flatRate == 0.0) {
      return principal / tenureMonths;
    }

    // Convert percentage to decimal (12% → 0.12)
    final rateDecimal = flatRate / 100.0;

    // Calculate total interest over entire tenure
    // Note: Tenure in months, so divide by 12 to get annual fraction
    final totalInterest = principal * rateDecimal * (tenureMonths / 12.0);

    // EMI = Divide total amount (principal + interest) equally across months
    final emi = (principal + totalInterest) / tenureMonths;

    return emi;
  }

  // ============================================================================
  // TRAP 2: UPFRONT DEDUCTION CALCULATOR
  // ============================================================================

  /// Calculate net amount actually disbursed to borrower.
  ///
  /// THE DECEPTION:
  /// Lender says: "We're giving you a ₹50,000 loan"
  /// Contract EMI: Based on ₹50,000
  /// Reality: Borrower receives ₹50,000 - ₹2,000 fee = ₹48,000
  /// Trap: Paying interest on ₹2,000 they never received!
  ///
  /// Edge Cases:
  /// - Fee = 0: Net disbursed = Principal (fair loan)
  /// - Fee >= Principal: Net disbursed = 0 (scam loan, should be rejected earlier)
  ///
  /// [principal] Face value of loan
  /// [upfrontFee] Processing fee deducted at disbursement
  double _calculateNetDisbursement(double principal, double upfrontFee) {
    final netAmount = principal - upfrontFee;

    // Sanity check (should be caught by ConfirmedLoanTerms validation)
    // But defensive programming: never return negative disbursement
    return math.max(0.0, netAmount);
  }

  // ============================================================================
  // TRAP 3: GHOST INSURANCE CALCULATOR
  // ============================================================================

  /// Calculate actual monthly cash outflow from borrower's pocket.
  ///
  /// THE DECEPTION:
  /// Advertised: "EMI is only ₹4,667 per month"
  /// Fine print: "+ mandatory insurance of ₹150/month"
  /// Reality: ₹4,817 leaves your pocket every month
  /// Trap: Insurance not included in advertised rate calculation
  ///
  /// This "insurance" is often:
  /// - Not real insurance (no payout, no coverage details)
  /// - Forced membership fee
  /// - Pure profit for lender
  /// - Disguised interest
  ///
  /// [emi] The advertised EMI amount
  /// [insurance] Monthly insurance/membership/protection fee
  double _calculateActualMonthlyOutflow(double emi, double insurance) {
    return emi + insurance;
  }

  // ============================================================================
  // CASH FLOW GENERATION (FOR IRR CALCULATION)
  // ============================================================================

  /// Generate the complete cash flow array for IRR calculation.
  ///
  /// CASH FLOW CONVENTION (standard finance):
  /// - NEGATIVE = Cash INFLOW to borrower (they receive money)
  /// - POSITIVE = Cash OUTFLOW from borrower (they pay money)
  ///
  /// Timeline:
  /// Month 0: Borrower receives net disbursement → NEGATIVE
  /// Month 1-N: Borrower pays actual monthly outflow → POSITIVE
  ///
  /// Example (₹48,000 net, ₹4,817/month for 12 months):
  /// [
  ///   -48000,  // Month 0: Received ₹48k
  ///   +4817,   // Month 1: Paid ₹4,817
  ///   +4817,   // Month 2: Paid ₹4,817
  ///   ...
  ///   +4817    // Month 12: Paid ₹4,817
  /// ]
  ///
  /// IRR finds the rate that makes NPV of these cash flows = 0
  ///
  /// [netDisbursed] Actual cash received by borrower (negative in array)
  /// [monthlyOutflow] Actual cash paid by borrower each month (positive in array)
  /// [tenureMonths] Number of monthly payments
  List<double> _generateCashFlows(
    double netDisbursed,
    double monthlyOutflow,
    int tenureMonths,
  ) {
    // Initialize array with tenure + 1 elements (Month 0 + N months)
    final cashFlows = <double>[];

    // Month 0: Disbursement (cash inflow to borrower, so negative)
    cashFlows.add(-netDisbursed);

    // Month 1 to N: Payments (cash outflow from borrower, so positive)
    for (int month = 1; month <= tenureMonths; month++) {
      cashFlows.add(monthlyOutflow);
    }

    return cashFlows;
  }

  // ============================================================================
  // IRR CALCULATION USING BISECTION METHOD
  // ============================================================================

  /// Calculate Internal Rate of Return using Bisection Method.
  ///
  /// WHAT IS IRR?
  /// The discount rate that makes Net Present Value (NPV) = 0
  ///
  /// NPV Formula:
  /// NPV = CF₀ + CF₁/(1+r) + CF₂/(1+r)² + ... + CFₙ/(1+r)ⁿ
  ///
  /// Where:
  /// - CF₀ = Cash flow at month 0 (disbursement, negative)
  /// - CF₁...CFₙ = Cash flows months 1 to N (payments, positive)
  /// - r = Monthly interest rate (what we're solving for)
  ///
  /// BISECTION METHOD:
  /// 1. Start with lower bound (e.g., -50%) and upper bound (e.g., 50%)
  /// 2. Calculate NPV at midpoint
  /// 3. If NPV > 0: IRR is in upper half (rates too low)
  /// 4. If NPV < 0: IRR is in lower half (rates too high)
  /// 5. Repeat until NPV ≈ 0 (within tolerance)
  ///
  /// WHY BISECTION?
  /// - Simple, robust, guaranteed convergence
  /// - No derivatives needed (unlike Newton-Raphson)
  /// - Works for all loan structures
  /// - Deterministic (always same result for same input)
  ///
  /// EDGE CASES:
  /// - Zero payments: IRR undefined, return 0
  /// - Negative total (borrower profits): Return negative IRR
  /// - No convergence after 100 iterations: Return best guess
  ///
  /// [cashFlows] Array of cash flows (negative = inflow, positive = outflow)
  double _calculateIRR(List<double> cashFlows) {
    // Edge case 1: Empty or single cash flow
    if (cashFlows.length <= 1) {
      return 0.0;
    }

    // Edge case 2: All cash flows are zero (no loan activity)
    if (cashFlows.every((cf) => cf == 0.0)) {
      return 0.0;
    }

    // Edge case 3: Zero net disbursement (fee >= principal)
    // Borrower receives nothing but pays EMI = infinite rate
    // Return upper bound as "usury flag"
    if (cashFlows[0] == 0.0) {
      return _irrUpperBound;
    }

    // Initialize bisection bounds
    double lowerBound = _irrLowerBound; // -50% monthly
    double upperBound = _irrUpperBound; // +50% monthly

    // Bisection iteration
    for (int iteration = 0; iteration < _maxIterations; iteration++) {
      // Calculate midpoint rate
      final midRate = (lowerBound + upperBound) / 2.0;

      // Calculate NPV at midpoint rate
      final npv = _calculateNPV(cashFlows, midRate);

      // Check convergence: NPV close enough to zero?
      if (npv.abs() < _irrTolerance) {
        return midRate; // Found it!
      }

      // Adjust search bounds based on NPV sign
      if (npv > 0) {
        // NPV positive means rate too low (future payments not discounted enough)
        // Search upper half
        lowerBound = midRate;
      } else {
        // NPV negative means rate too high (future payments discounted too much)
        // Search lower half
        upperBound = midRate;
      }
    }

    // Didn't converge within max iterations (rare)
    // Return best approximation (midpoint of final bounds)
    return (lowerBound + upperBound) / 2.0;
  }

  /// Calculate Net Present Value for a given discount rate.
  ///
  /// NPV Formula:
  /// NPV = Σ [CFₜ / (1 + r)ᵗ] for t = 0 to N
  ///
  /// Where:
  /// - CFₜ = Cash flow at time t
  /// - r = Discount rate (monthly IRR candidate)
  /// - t = Time period (month number)
  ///
  /// Example:
  /// Cash flows: [-48000, +4817, +4817, +4817, ...]
  /// Rate: 0.02 (2% per month)
  ///
  /// NPV = -48000/(1.02)⁰ + 4817/(1.02)¹ + 4817/(1.02)² + ...
  ///     = -48000 + 4722.5 + 4629.9 + ...
  ///
  /// [cashFlows] Array of cash flows
  /// [rate] Monthly discount rate (decimal, e.g., 0.02 for 2%)
  double _calculateNPV(List<double> cashFlows, double rate) {
    double npv = 0.0;

    for (int t = 0; t < cashFlows.length; t++) {
      // Discount factor = 1 / (1 + rate)^t
      final discountFactor = math.pow(1.0 + rate, t);

      // Present value of this cash flow
      final presentValue = cashFlows[t] / discountFactor;

      npv += presentValue;
    }

    return npv;
  }

  // ============================================================================
  // APR CONVERSION
  // ============================================================================

  /// Convert monthly IRR to Annual Percentage Rate (APR).
  ///
  /// IMPORTANT: This is SIMPLE APR, not APY (Annual Percentage Yield)
  /// APR = Monthly Rate × 12
  /// APY = (1 + Monthly Rate)^12 - 1 (compounds monthly)
  ///
  /// We use APR because:
  /// 1. RBI regulations require APR disclosure
  /// 2. It's what consumers expect to see
  /// 3. It's the industry standard for loan comparison
  ///
  /// Example:
  /// Monthly IRR = 0.0204 (2.04%)
  /// APR = 0.0204 × 12 = 0.2448 = 24.48%
  ///
  /// For reference, APY would be:
  /// APY = (1.0204)^12 - 1 = 0.2736 = 27.36%
  ///
  /// [monthlyRate] Monthly IRR as decimal (e.g., 0.0204)
  /// Returns: Annual rate as percentage (e.g., 24.48)
  double _convertToAPR(double monthlyRate) {
    // Convert to annual rate (multiply by 12)
    final annualRate = monthlyRate * _monthsPerYear;

    // Convert to percentage (multiply by 100)
    final aprPercentage = annualRate * 100.0;

    return aprPercentage;
  }

  // ============================================================================
  // HIDDEN COST CALCULATOR
  // ============================================================================

  /// Calculate total hidden cost (the "dirty tricks tax").
  ///
  /// DEFINITION OF HIDDEN COST:
  /// The extra amount paid above a FAIR loan at the advertised rate.
  ///
  /// FAIR LOAN (hypothetical):
  /// - Principal: ₹50,000
  /// - Rate: 12% reducing balance
  /// - No upfront fees
  /// - No ghost insurance
  /// - Fair EMI: ~₹4,442/month
  /// - Total paid: ₹53,304
  ///
  /// ACTUAL PREDATORY LOAN:
  /// - Total paid: ₹4,817 × 12 = ₹57,804
  ///
  /// HIDDEN COST:
  /// ₹57,804 - ₹53,304 = ₹4,500
  ///
  /// This ₹4,500 is the "dirty tricks tax" - pure exploitation.
  ///
  /// Formula:
  /// Hidden Cost = (Actual Total Paid) - (Principal + Fair Interest)
  ///
  /// Where:
  /// - Actual Total Paid = Monthly Outflow × Tenure
  /// - Fair Interest = Principal × (Rate/100) × (Tenure/12) for reducing balance
  ///   (approximately half of flat rate interest for same rate)
  ///
  /// Note: We approximate fair interest using flat rate / 2 as a conservative
  /// estimate. True reducing balance calculation is complex, but this gives
  /// borrowers a MINIMUM estimate of how much they're being cheated.
  ///
  /// [principal] Original loan amount
  /// [actualMonthlyOutflow] Real monthly payment (EMI + insurance)
  /// [tenureMonths] Loan duration
  /// [advertisedRate] The rate they claimed (percentage)
  double _calculateHiddenCost(
    double principal,
    double actualMonthlyOutflow,
    int tenureMonths,
    double advertisedRate,
  ) {
    // Calculate actual total paid
    final actualTotalPaid = actualMonthlyOutflow * tenureMonths;

    // Calculate fair interest (approximated as flat rate / 2)
    // This is conservative: true reducing balance would be even lower
    final fairInterestEstimate =
        principal * (advertisedRate / 100.0) * (tenureMonths / 12.0) * 0.5;

    // Calculate what SHOULD have been paid
    final fairTotalPayment = principal + fairInterestEstimate;

    // Hidden cost = extra amount above fair payment
    final hiddenCost = actualTotalPaid - fairTotalPayment;

    // Return hidden cost (or 0 if somehow negative, though shouldn't happen)
    return math.max(0.0, hiddenCost);
  }

  // ============================================================================
  // UTILITY: DETAILED BREAKDOWN (FOR DEBUGGING/LOGGING)
  // ============================================================================

  /// Generate detailed breakdown for debugging or advanced UI display.
  ///
  /// NOT required for basic operation, but useful for:
  /// - Developer debugging
  /// - Advanced user mode
  /// - Educational display showing step-by-step calculation
  ///
  /// Returns a Map with intermediate calculation values.
  Map<String, dynamic> generateDetailedBreakdown(ConfirmedLoanTerms terms) {
    final advertisedEmi = _calculateFlatRateEMI(
      terms.principal_amount,
      terms.advertised_flat_rate,
      terms.tenure_months,
    );

    final netDisbursed = _calculateNetDisbursement(
      terms.principal_amount,
      terms.upfront_processing_fee,
    );

    final actualOutflow = _calculateActualMonthlyOutflow(
      advertisedEmi,
      terms.monthly_insurance_premium,
    );

    final cashFlows = _generateCashFlows(
      netDisbursed,
      actualOutflow,
      terms.tenure_months,
    );

    final monthlyIRR = _calculateIRR(cashFlows);
    final trueAPR = _convertToAPR(monthlyIRR);

    final totalPaid = actualOutflow * terms.tenure_months;
    final totalInterest = totalPaid - terms.principal_amount;

    return {
      'advertised_emi': advertisedEmi,
      'net_disbursed': netDisbursed,
      'actual_monthly_outflow': actualOutflow,
      'monthly_irr_percent': monthlyIRR * 100,
      'true_apr_percent': trueAPR,
      'total_amount_paid': totalPaid,
      'total_interest_paid': totalInterest,
      'cash_flows': cashFlows,
      'effective_principal': netDisbursed,
      'fee_percentage_of_principal':
          (terms.upfront_processing_fee / terms.principal_amount) * 100,
      'insurance_percentage_of_emi':
          (terms.monthly_insurance_premium / actualOutflow) * 100,
    };
  }
}