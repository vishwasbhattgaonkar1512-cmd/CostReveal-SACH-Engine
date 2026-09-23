// lib/models/loan_terms.dart
// ============================================================================
// CostReveal: The Dirty Tricks Detector
// Data Models - Zero-Trust Boundary Implementation
// ============================================================================
// Philosophy: "AI reads. Human verifies. Mathematics decides."
//
// This file implements the TYPE-LEVEL TRUST BOUNDARY:
// - CandidateLoanTerms: UNTRUSTED data from AI extraction (nullable)
// - ConfirmedLoanTerms: TRUSTED data post-human validation (non-nullable)
// - CalculationResult: DETERMINISTIC output from math engine
//
// Author: M1 (Engine & Compliance)
// Critical: These exact variable names are the DATA CONTRACT with UI/AI teams
// ============================================================================

import 'package:flutter/foundation.dart';

/// ============================================================================
/// UNTRUSTED ZONE: CandidateLoanTerms
/// ============================================================================
/// Represents loan data extracted by AI (Gemini) from documents.
/// ALL fields are nullable because AI extraction may be incomplete or fail.
/// This data MUST NOT be used for calculations until validated by a human.
///
/// Trust Level: ZERO
/// Source: AI/OCR extraction
/// Next Step: Human validation screen
/// ============================================================================
@immutable
class CandidateLoanTerms {
  /// Principal loan amount in INR (e.g., 50000.0)
  /// Null if AI failed to extract this field
  final double? principal_amount;

  /// Loan duration in months (e.g., 12, 24, 36)
  /// Null if AI failed to extract this field
  final int? tenure_months;

  /// The "advertised" flat interest rate as a percentage (e.g., 12.0 for 12%)
  /// WARNING: This is often DECEPTIVE - it's NOT the true APR
  /// Null if AI failed to extract this field
  final double? advertised_flat_rate;

  /// Upfront processing fee in INR (e.g., 2000.0)
  /// TRAP: Deducted from disbursement, but EMI calculated on full principal
  /// Null if AI failed to extract or if fee is 0
  final double? upfront_processing_fee;

  /// Monthly insurance/membership premium in INR (e.g., 150.0)
  /// TRAP: "Ghost Insurance" - forced add-ons not included in advertised rate
  /// Null if AI failed to extract or if no insurance
  final double? monthly_insurance_premium;

  /// Constructor with all nullable fields
  const CandidateLoanTerms({
    this.principal_amount,
    this.tenure_months,
    this.advertised_flat_rate,
    this.upfront_processing_fee,
    this.monthly_insurance_premium,
  });

  /// Factory: Create from JSON (for AI service integration)
  factory CandidateLoanTerms.fromJson(Map<String, dynamic> json) {
    return CandidateLoanTerms(
      principal_amount: json['principal_amount'] as double?,
      tenure_months: json['tenure_months'] as int?,
      advertised_flat_rate: json['advertised_flat_rate'] as double?,
      upfront_processing_fee: json['upfront_processing_fee'] as double?,
      monthly_insurance_premium: json['monthly_insurance_premium'] as double?,
    );
  }

  /// Convert to JSON (for persistence or debugging)
  Map<String, dynamic> toJson() {
    return {
      'principal_amount': principal_amount,
      'tenure_months': tenure_months,
      'advertised_flat_rate': advertised_flat_rate,
      'upfront_processing_fee': upfront_processing_fee,
      'monthly_insurance_premium': monthly_insurance_premium,
    };
  }

  /// Validation: Check if ALL required fields are present
  /// Returns true ONLY if this candidate can be promoted to Confirmed
  bool get isComplete {
    return principal_amount != null &&
        tenure_months != null &&
        advertised_flat_rate != null &&
        upfront_processing_fee != null &&
        monthly_insurance_premium != null;
  }

  /// Validation: Get list of missing field names (for UI error display)
  List<String> get missingFields {
    final missing = <String>[];
    if (principal_amount == null) missing.add('principal_amount');
    if (tenure_months == null) missing.add('tenure_months');
    if (advertised_flat_rate == null) missing.add('advertised_flat_rate');
    if (upfront_processing_fee == null) missing.add('upfront_processing_fee');
    if (monthly_insurance_premium == null) {
      missing.add('monthly_insurance_premium');
    }
    return missing;
  }

  /// Create a copy with modified fields (for human correction in UI)
  CandidateLoanTerms copyWith({
    double? principal_amount,
    int? tenure_months,
    double? advertised_flat_rate,
    double? upfront_processing_fee,
    double? monthly_insurance_premium,
  }) {
    return CandidateLoanTerms(
      principal_amount: principal_amount ?? this.principal_amount,
      tenure_months: tenure_months ?? this.tenure_months,
      advertised_flat_rate: advertised_flat_rate ?? this.advertised_flat_rate,
      upfront_processing_fee:
          upfront_processing_fee ?? this.upfront_processing_fee,
      monthly_insurance_premium:
          monthly_insurance_premium ?? this.monthly_insurance_premium,
    );
  }

  @override
  String toString() {
    return 'CandidateLoanTerms(principal: $principal_amount, '
        'tenure: $tenure_months, rate: $advertised_flat_rate%, '
        'fee: $upfront_processing_fee, insurance: $monthly_insurance_premium)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CandidateLoanTerms &&
        other.principal_amount == principal_amount &&
        other.tenure_months == tenure_months &&
        other.advertised_flat_rate == advertised_flat_rate &&
        other.upfront_processing_fee == upfront_processing_fee &&
        other.monthly_insurance_premium == monthly_insurance_premium;
  }

  @override
  int get hashCode {
    return Object.hash(
      principal_amount,
      tenure_months,
      advertised_flat_rate,
      upfront_processing_fee,
      monthly_insurance_premium,
    );
  }
}

/// ============================================================================
/// TRUSTED ZONE: ConfirmedLoanTerms
/// ============================================================================
/// Represents loan data that has been VALIDATED by a human field worker.
/// ALL fields are required and non-nullable.
/// This is the ONLY data type the math engine will accept.
///
/// Trust Level: HUMAN-VERIFIED
/// Source: Human validation screen
/// Next Step: Mathematics engine calculation
/// ============================================================================
@immutable
class ConfirmedLoanTerms {
  /// Principal loan amount in INR - REQUIRED, VERIFIED
  /// Must be > 0 (enforced by validation)
  final double principal_amount;

  /// Loan duration in months - REQUIRED, VERIFIED
  /// Must be > 0 (enforced by validation)
  final int tenure_months;

  /// The advertised flat interest rate as a percentage - REQUIRED, VERIFIED
  /// Can be 0 (rare but valid for promotional loans)
  final double advertised_flat_rate;

  /// Upfront processing fee in INR - REQUIRED, VERIFIED
  /// Use 0.0 if no fee exists (explicit zero, not null)
  final double upfront_processing_fee;

  /// Monthly insurance/membership premium in INR - REQUIRED, VERIFIED
  /// Use 0.0 if no insurance exists (explicit zero, not null)
  final double monthly_insurance_premium;

  /// Private constructor - use factory methods to create instances
  const ConfirmedLoanTerms._({
    required this.principal_amount,
    required this.tenure_months,
    required this.advertised_flat_rate,
    required this.upfront_processing_fee,
    required this.monthly_insurance_premium,
  });

  /// ============================================================================
  /// CRITICAL: Zero-Trust Boundary Crossing Point
  /// ============================================================================
  /// Factory: Promote CandidateLoanTerms to ConfirmedLoanTerms
  /// This is the ONLY way untrusted data becomes trusted.
  ///
  /// Validation Rules (STRICT):
  /// 1. All fields must be non-null
  /// 2. principal_amount must be > 0
  /// 3. tenure_months must be > 0 and <= 360 (max 30 years)
  /// 4. advertised_flat_rate must be >= 0 and < 200 (sanity check)
  /// 5. upfront_processing_fee must be >= 0
  /// 6. monthly_insurance_premium must be >= 0
  ///
  /// Returns: ConfirmedLoanTerms if valid, throws ArgumentError if invalid
  /// ============================================================================
  factory ConfirmedLoanTerms.fromCandidate(CandidateLoanTerms candidate) {
    // Rule 1: Completeness check
    if (!candidate.isComplete) {
      throw ArgumentError(
        'Cannot confirm incomplete candidate. Missing fields: ${candidate.missingFields.join(", ")}',
      );
    }

    // Extract non-null values (we know they exist from isComplete check)
    final principal = candidate.principal_amount!;
    final tenure = candidate.tenure_months!;
    final rate = candidate.advertised_flat_rate!;
    final fee = candidate.upfront_processing_fee!;
    final insurance = candidate.monthly_insurance_premium!;

    // Rule 2: Principal validation
    if (principal <= 0) {
      throw ArgumentError(
        'Invalid principal_amount: $principal. Must be > 0.',
      );
    }

    // Rule 3: Tenure validation
    if (tenure <= 0 || tenure > 360) {
      throw ArgumentError(
        'Invalid tenure_months: $tenure. Must be > 0 and <= 360.',
      );
    }

    // Rule 4: Interest rate validation (sanity check for typos)
    if (rate < 0 || rate >= 200) {
      throw ArgumentError(
        'Invalid advertised_flat_rate: $rate%. Must be >= 0 and < 200.',
      );
    }

    // Rule 5: Processing fee validation
    if (fee < 0) {
      throw ArgumentError(
        'Invalid upfront_processing_fee: $fee. Must be >= 0.',
      );
    }

    // Rule 6: Insurance validation
    if (insurance < 0) {
      throw ArgumentError(
        'Invalid monthly_insurance_premium: $insurance. Must be >= 0.',
      );
    }

    // All validations passed - create TRUSTED instance
    return ConfirmedLoanTerms._(
      principal_amount: principal,
      tenure_months: tenure,
      advertised_flat_rate: rate,
      upfront_processing_fee: fee,
      monthly_insurance_premium: insurance,
    );
  }

  /// Factory: Create directly from validated values (for testing/manual entry)
  factory ConfirmedLoanTerms.fromValues({
    required double principal_amount,
    required int tenure_months,
    required double advertised_flat_rate,
    required double upfront_processing_fee,
    required double monthly_insurance_premium,
  }) {
    // Reuse validation logic by creating a candidate and promoting it
    final candidate = CandidateLoanTerms(
      principal_amount: principal_amount,
      tenure_months: tenure_months,
      advertised_flat_rate: advertised_flat_rate,
      upfront_processing_fee: upfront_processing_fee,
      monthly_insurance_premium: monthly_insurance_premium,
    );
    return ConfirmedLoanTerms.fromCandidate(candidate);
  }

  /// Convert to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'principal_amount': principal_amount,
      'tenure_months': tenure_months,
      'advertised_flat_rate': advertised_flat_rate,
      'upfront_processing_fee': upfront_processing_fee,
      'monthly_insurance_premium': monthly_insurance_premium,
    };
  }

  /// Factory: Create from JSON (for persistence/deserialization)
  factory ConfirmedLoanTerms.fromJson(Map<String, dynamic> json) {
    return ConfirmedLoanTerms.fromValues(
      principal_amount: json['principal_amount'] as double,
      tenure_months: json['tenure_months'] as int,
      advertised_flat_rate: json['advertised_flat_rate'] as double,
      upfront_processing_fee: json['upfront_processing_fee'] as double,
      monthly_insurance_premium: json['monthly_insurance_premium'] as double,
    );
  }

  @override
  String toString() {
    return 'ConfirmedLoanTerms(principal: ₹$principal_amount, '
        'tenure: $tenure_months months, rate: $advertised_flat_rate%, '
        'fee: ₹$upfront_processing_fee, insurance: ₹$monthly_insurance_premium/mo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConfirmedLoanTerms &&
        other.principal_amount == principal_amount &&
        other.tenure_months == tenure_months &&
        other.advertised_flat_rate == advertised_flat_rate &&
        other.upfront_processing_fee == upfront_processing_fee &&
        other.monthly_insurance_premium == monthly_insurance_premium;
  }

  @override
  int get hashCode {
    return Object.hash(
      principal_amount,
      tenure_months,
      advertised_flat_rate,
      upfront_processing_fee,
      monthly_insurance_premium,
    );
  }
}

/// ============================================================================
/// OUTPUT: CalculationResult
/// ============================================================================
/// Represents the DETERMINISTIC output from the mathematics engine.
/// This is the "truth" that exposes predatory lending practices.
///
/// Trust Level: MATHEMATICAL CERTAINTY
/// Source: MathEngine.exposeTheTruth()
/// Next Step: PDF generation and RBI submission
///
/// EVIDENCE TRACE DATA:
/// This class exposes ALL intermediate calculation values needed
/// for the "How did we calculate this?" evidence expander in the UI.
///
/// CASH FLOW TRACE (Step 1 Addition):
/// Human-readable List<String> formatted math steps.
/// Field: cash_flow_trace
/// Consumed by: UI evidence expander, PDF generator
/// ============================================================================
@immutable
class CalculationResult {
  // ========== CORE OUTPUT FIELDS (Original - DATA CONTRACT - DO NOT RENAME) ==========

  /// The TRUE Annual Percentage Rate (APR) calculated using IRR
  /// This is what the borrower ACTUALLY pays, not the advertised rate
  /// Example: Advertised 12% might be TRUE 24.5% APR
  /// UI Label: "Effective Annualized Cost"
  final double true_apr;

  /// Total hidden cost = (Total actual paid) - (Principal + Fair interest)
  /// This is the "dirty trick" amount in INR that enriches the lender
  final double total_hidden_cost;

  /// The actual monthly cash outflow = EMI + Insurance
  /// This is what leaves the borrower's pocket each month
  final double actual_monthly_outflow;

  /// Net amount actually received by borrower = Principal - Upfront fees
  /// TRAP: Borrower pays EMI on principal, but receives LESS
  /// UI Label: "Net Amount Received"
  final double net_disbursed_amount;

  // ========== EVIDENCE TRACE FIELDS (Existing) ==========

  /// Sanctioned loan amount (before any deductions)
  final double sanctioned_amount;

  /// Upfront processing fee deducted from disbursement
  final double processing_fee;

  /// Monthly insurance/membership premium charged
  final double insurance_cost;

  /// Complete cash flow timeline used for IRR calculation
  /// Month 0 = -net_disbursed_amount (negative = money received)
  /// Months 1-N = +actual_monthly_outflow (positive = money paid)
  final List<double> monthly_cash_flows;

  /// Monthly Internal Rate of Return (as percentage)
  final double monthly_irr;

  // ========== STEP 1 ADDITION: CASH FLOW TRACE ==========

  /// Human-readable evidence trace of the calculation steps.
  ///
  /// PURPOSE: Frontend "Evidence Expander" and PDF math section.
  /// FORMAT:  Each string is one logical step in the money flow.
  ///
  /// Guaranteed order:
  ///   [0] "Sanctioned: ₹X"
  ///   [1] "Minus Processing Fee: -₹Y"          (omitted if fee = 0)
  ///   [2] "Minus Insurance (total): -₹Z"        (omitted if insurance = 0)
  ///   [3] "Net Received: ₹A"
  ///   [4] "Monthly EMI (flat-rate): ₹B"
  ///   [5] "Monthly Insurance Premium: ₹C"       (omitted if insurance = 0)
  ///   [6] "Total Monthly Outflow: ₹D"
  ///   [7] "True APR (IRR method): X.XX%"
  ///   [8] "Total Hidden Cost: ₹E"
  ///
  /// Note: Lines with zero values are omitted to keep the trace clean.
  /// The UI team must iterate and display, never index directly.
  ///
  /// Populated by: MathEngine._buildCashFlowTrace()
  /// Consumed by:  UI evidence expander, PDF generator (Step 2)
  final List<String> cash_flow_trace;

  const CalculationResult({
    // Core outputs
    required this.true_apr,
    required this.total_hidden_cost,
    required this.actual_monthly_outflow,
    required this.net_disbursed_amount,
    // Evidence trace data
    required this.sanctioned_amount,
    required this.processing_fee,
    required this.insurance_cost,
    required this.monthly_cash_flows,
    required this.monthly_irr,
    // Step 1: Cash flow trace
    required this.cash_flow_trace,
  });

  /// Convert to JSON (for persistence/API)
  Map<String, dynamic> toJson() {
    return {
      'true_apr': true_apr,
      'total_hidden_cost': total_hidden_cost,
      'actual_monthly_outflow': actual_monthly_outflow,
      'net_disbursed_amount': net_disbursed_amount,
      'sanctioned_amount': sanctioned_amount,
      'processing_fee': processing_fee,
      'insurance_cost': insurance_cost,
      'monthly_cash_flows': monthly_cash_flows,
      'monthly_irr': monthly_irr,
      'cash_flow_trace': cash_flow_trace,
    };
  }

  /// Factory: Create from JSON
  factory CalculationResult.fromJson(Map<String, dynamic> json) {
    return CalculationResult(
      true_apr: json['true_apr'] as double,
      total_hidden_cost: json['total_hidden_cost'] as double,
      actual_monthly_outflow: json['actual_monthly_outflow'] as double,
      net_disbursed_amount: json['net_disbursed_amount'] as double,
      sanctioned_amount: json['sanctioned_amount'] as double,
      processing_fee: json['processing_fee'] as double,
      insurance_cost: json['insurance_cost'] as double,
      monthly_cash_flows: (json['monthly_cash_flows'] as List<dynamic>)
          .map((e) => e as double)
          .toList(),
      monthly_irr: json['monthly_irr'] as double,
      cash_flow_trace: (json['cash_flow_trace'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  /// Human-readable summary for logging/debugging
  @override
  String toString() {
    return 'CalculationResult(\n'
        '  TRUE APR: ${true_apr.toStringAsFixed(2)}%\n'
        '  Hidden Cost: ₹${total_hidden_cost.toStringAsFixed(2)}\n'
        '  Monthly Outflow: ₹${actual_monthly_outflow.toStringAsFixed(2)}\n'
        '  Net Disbursed: ₹${net_disbursed_amount.toStringAsFixed(2)}\n'
        '  Sanctioned: ₹${sanctioned_amount.toStringAsFixed(2)}\n'
        '  Processing Fee: ₹${processing_fee.toStringAsFixed(2)}\n'
        '  Insurance: ₹${insurance_cost.toStringAsFixed(2)}/mo\n'
        '  Monthly IRR: ${monthly_irr.toStringAsFixed(4)}%\n'
        '  Cash Flows: ${monthly_cash_flows.length} months\n'
        '  Evidence Trace (${cash_flow_trace.length} steps):\n'
        '${cash_flow_trace.map((s) => '    → $s').join('\n')}\n'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalculationResult &&
        other.true_apr == true_apr &&
        other.total_hidden_cost == total_hidden_cost &&
        other.actual_monthly_outflow == actual_monthly_outflow &&
        other.net_disbursed_amount == net_disbursed_amount &&
        other.sanctioned_amount == sanctioned_amount &&
        other.processing_fee == processing_fee &&
        other.insurance_cost == insurance_cost &&
        listEquals(other.monthly_cash_flows, monthly_cash_flows) &&
        other.monthly_irr == monthly_irr &&
        listEquals(other.cash_flow_trace, cash_flow_trace);
  }

  @override
  int get hashCode {
    return Object.hash(
      true_apr,
      total_hidden_cost,
      actual_monthly_outflow,
      net_disbursed_amount,
      sanctioned_amount,
      processing_fee,
      insurance_cost,
      Object.hashAll(monthly_cash_flows),
      monthly_irr,
      Object.hashAll(cash_flow_trace),
    );
  }
}