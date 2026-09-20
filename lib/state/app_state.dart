// lib/state/app_state.dart
// ============================================================================
// CostReveal: The Dirty Tricks Detector
// Application State Management - Provider Pattern
// ============================================================================
// Philosophy: "AI reads. Human verifies. Mathematics decides."
//
// This file implements the APPLICATION STATE layer that orchestrates the
// complete workflow:
//
// WORKFLOW STATES:
// 1. IDLE → No data yet
// 2. AI_EXTRACTED → CandidateLoanTerms available (UNTRUSTED)
// 3. HUMAN_VALIDATED → ConfirmedLoanTerms available (TRUSTED)
// 4. CALCULATED → CalculationResult available (MATHEMATICAL TRUTH)
// 5. PDF_GENERATED → Evidence document ready for submission
//
// STATE TRANSITIONS (ONE-WAY, FORWARD ONLY):
// IDLE → AI_EXTRACTED → HUMAN_VALIDATED → CALCULATED → PDF_GENERATED
//
// CRITICAL INVARIANT:
// Math engine can ONLY access ConfirmedLoanTerms (never CandidateLoanTerms).
// This enforces the Zero-Trust Boundary at the architecture level.
//
// Author: M1 (Engine & Compliance)
// ============================================================================

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/loan_terms.dart';
import '../engine/math_engine.dart';
import '../engine/pdf_generator.dart';

/// ============================================================================
/// APPLICATION STATE PROVIDER
/// ============================================================================
/// Central state management for the entire CostReveal application.
/// Uses ChangeNotifier pattern for reactive UI updates.
///
/// This class is the SINGLE SOURCE OF TRUTH for:
/// - Current workflow state
/// - Loan terms data (candidate and confirmed)
/// - Calculation results
/// - Error states
/// - PDF generation status
///
/// UI components listen to this provider and rebuild when state changes.
/// ============================================================================
class AppProvider extends ChangeNotifier {
  // ==========================================================================
  // PRIVATE STATE (Only accessible via getters and methods)
  // ==========================================================================

  /// Current workflow state
  AppState _currentState = AppState.idle;

  /// UNTRUSTED: Data extracted by AI (nullable, may be incomplete)
  CandidateLoanTerms? _candidateTerms;

  /// TRUSTED: Data verified by human (non-nullable when set)
  ConfirmedLoanTerms? _confirmedTerms;

  /// MATHEMATICAL TRUTH: Result from math engine
  CalculationResult? _calculationResult;

  /// Generated PDF evidence document (byte array)
  Uint8List? _generatedPDF;

  /// Current error message (null if no error)
  String? _errorMessage;

  /// Loading state (true during async operations)
  bool _isLoading = false;

  /// Math engine instance (stateless, reusable)
  final MathEngine _mathEngine = MathEngine();

  // ==========================================================================
  // PUBLIC GETTERS (Read-only access to state)
  // ==========================================================================

  /// Current workflow state
  AppState get currentState => _currentState;

  /// UNTRUSTED candidate terms from AI
  CandidateLoanTerms? get candidateTerms => _candidateTerms;

  /// TRUSTED confirmed terms from human validation
  ConfirmedLoanTerms? get confirmedTerms => _confirmedTerms;

  /// Calculation result from math engine
  CalculationResult? get calculationResult => _calculationResult;

  /// Generated PDF document
  Uint8List? get generatedPDF => _generatedPDF;

  /// Current error message
  String? get errorMessage => _errorMessage;

  /// Loading state indicator
  bool get isLoading => _isLoading;

  /// Check if candidate data is complete and ready for validation
  bool get isCandidateComplete => _candidateTerms?.isComplete ?? false;

  /// Check if we have confirmed terms ready for calculation
  bool get hasConfirmedTerms => _confirmedTerms != null;

  /// Check if we have calculation results
  bool get hasCalculationResult => _calculationResult != null;

  /// Check if we have generated PDF
  bool get hasPDF => _generatedPDF != null;

  // ==========================================================================
  // STATE TRANSITION: IDLE → AI_EXTRACTED
  // ==========================================================================

  /// Set candidate loan terms from AI extraction.
  ///
  /// This is the FIRST step in the workflow. AI/OCR has extracted data from
  /// a loan document, but it's UNTRUSTED and may be incomplete.
  ///
  /// CRITICAL: This data CANNOT be used for calculations yet. It must pass
  /// through human validation first.
  ///
  /// [terms] The extracted loan terms (may have null fields)
  ///
  /// State Transition: IDLE → AI_EXTRACTED
  void setCandidateTerms(CandidateLoanTerms terms) {
    _candidateTerms = terms;
    _currentState = AppState.aiExtracted;
    _errorMessage = null; // Clear any previous errors
    
    // Clear downstream state (new extraction invalidates old validation/calculations)
    _confirmedTerms = null;
    _calculationResult = null;
    _generatedPDF = null;

    notifyListeners();
  }

  /// Update a specific field in candidate terms (for human corrections).
  ///
  /// This allows the UI to let humans correct individual fields before
  /// confirming the entire dataset.
  ///
  /// [updatedTerms] The modified candidate terms
  void updateCandidateTerms(CandidateLoanTerms updatedTerms) {
    _candidateTerms = updatedTerms;
    _errorMessage = null;
    notifyListeners();
  }

  // ==========================================================================
  // STATE TRANSITION: AI_EXTRACTED → HUMAN_VALIDATED
  // ==========================================================================

  /// Validate and confirm candidate terms (CROSSING THE TRUST BOUNDARY).
  ///
  /// This is the CRITICAL GATE. When a human confirms the data, we attempt
  /// to promote CandidateLoanTerms to ConfirmedLoanTerms.
  ///
  /// VALIDATION RULES (enforced by ConfirmedLoanTerms):
  /// - All fields must be non-null
  /// - principal_amount > 0
  /// - tenure_months > 0 and <= 360
  /// - advertised_flat_rate >= 0 and < 200
  /// - upfront_processing_fee >= 0
  /// - monthly_insurance_premium >= 0
  ///
  /// If validation FAILS, state remains AI_EXTRACTED and error is set.
  /// If validation SUCCEEDS, state advances to HUMAN_VALIDATED.
  ///
  /// Returns: true if validation succeeded, false otherwise
  ///
  /// State Transition: AI_EXTRACTED → HUMAN_VALIDATED (if valid)
  bool validateAndConfirmTerms() {
    // Precondition: Must have candidate terms
    if (_candidateTerms == null) {
      _errorMessage = 'No candidate terms to validate';
      notifyListeners();
      return false;
    }

    try {
      // Attempt to cross the trust boundary
      _confirmedTerms = ConfirmedLoanTerms.fromCandidate(_candidateTerms!);
      
      // Success! Update state
      _currentState = AppState.humanValidated;
      _errorMessage = null;
      
      // Clear downstream state (new confirmation invalidates old calculations)
      _calculationResult = null;
      _generatedPDF = null;

      notifyListeners();
      return true;

    } on ArgumentError catch (e) {
      // Validation failed - stay in AI_EXTRACTED state
      _errorMessage = 'Validation failed: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  /// Manually set confirmed terms (for testing or manual entry).
  ///
  /// This bypasses the candidate→confirmed flow and directly sets trusted data.
  /// Use this when data is entered manually by a human (not from AI extraction).
  ///
  /// [terms] Pre-validated confirmed terms
  ///
  /// State Transition: ANY → HUMAN_VALIDATED
  void setConfirmedTerms(ConfirmedLoanTerms terms) {
    _confirmedTerms = terms;
    _currentState = AppState.humanValidated;
    _errorMessage = null;

    // Clear downstream state
    _calculationResult = null;
    _generatedPDF = null;

    notifyListeners();
  }

  // ==========================================================================
  // STATE TRANSITION: HUMAN_VALIDATED → CALCULATED
  // ==========================================================================

  /// Calculate TRUE APR and expose predatory lending traps.
  ///
  /// This runs the math engine on TRUSTED, human-verified data.
  /// The calculation is 100% deterministic and offline.
  ///
  /// CRITICAL INVARIANT ENFORCED:
  /// This method can ONLY run if we have ConfirmedLoanTerms (not Candidate).
  /// This enforces the Zero-Trust Boundary at the code level.
  ///
  /// Returns: true if calculation succeeded, false otherwise
  ///
  /// State Transition: HUMAN_VALIDATED → CALCULATED
  bool calculateTrueAPR() {
    // Precondition: Must have confirmed terms
    if (_confirmedTerms == null) {
      _errorMessage = 'Cannot calculate: No confirmed terms available';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Run the math engine (deterministic, offline)
      _calculationResult = _mathEngine.exposeTheTruth(_confirmedTerms!);

      // Success! Update state
      _currentState = AppState.calculated;
      _errorMessage = null;
      
      // Clear downstream state (new calculation invalidates old PDF)
      _generatedPDF = null;

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      // Calculation error (should never happen with valid ConfirmedLoanTerms)
      _errorMessage = 'Calculation error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // STATE TRANSITION: CALCULATED → PDF_GENERATED
  // ==========================================================================

  /// Generate PDF evidence document.
  ///
  /// Creates a professional, RBI-ready PDF document with:
  /// - DRAFT watermark
  /// - Loan terms comparison (advertised vs actual)
  /// - TRUE APR vs advertised rate
  /// - Hidden cost breakdown
  /// - Mathematical proof (IRR methodology)
  ///
  /// Preconditions:
  /// - Must have confirmed terms
  /// - Must have calculation result
  ///
  /// [borrowerName] Optional borrower name for document
  /// [lenderName] Optional lender name for document
  ///
  /// Returns: true if PDF generated successfully, false otherwise
  ///
  /// State Transition: CALCULATED → PDF_GENERATED
  Future<bool> generatePDFEvidence({
    String? borrowerName,
    String? lenderName,
  }) async {
    // Preconditions
    if (_confirmedTerms == null || _calculationResult == null) {
      _errorMessage = 'Cannot generate PDF: Missing required data';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Generate PDF document
      _generatedPDF = await PDFGenerator.generateEvidenceDocument(
        terms: _confirmedTerms!,
        result: _calculationResult!,
        borrowerName: borrowerName,
        lenderName: lenderName,
        documentDate: DateTime.now(),
      );

      // Success! Update state
      _currentState = AppState.pdfGenerated;
      _errorMessage = null;
      _isLoading = false;

      notifyListeners();
      return true;

    } catch (e) {
      // PDF generation error
      _errorMessage = 'PDF generation error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Clear all error messages.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset application to IDLE state (clear all data).
  ///
  /// This is used when starting a new loan analysis or when the user
  /// wants to discard current work and start over.
  ///
  /// State Transition: ANY → IDLE
  void reset() {
    _currentState = AppState.idle;
    _candidateTerms = null;
    _confirmedTerms = null;
    _calculationResult = null;
    _generatedPDF = null;
    _errorMessage = null;
    _isLoading = false;

    notifyListeners();
  }

  /// Get detailed breakdown for advanced UI display or debugging.
  ///
  /// Precondition: Must have confirmed terms
  ///
  /// Returns: Map with detailed calculation breakdown, or null if unavailable
  Map<String, dynamic>? getDetailedBreakdown() {
    if (_confirmedTerms == null) return null;

    try {
      return _mathEngine.generateDetailedBreakdown(_confirmedTerms!);
    } catch (e) {
      return null;
    }
  }

  /// Check if we can proceed to next step in workflow.
  bool canProceedToValidation() => _candidateTerms != null && _candidateTerms!.isComplete;
  bool canProceedToCalculation() => _confirmedTerms != null;
  bool canProceedToPDFGeneration() => _confirmedTerms != null && _calculationResult != null;

  // ==========================================================================
  // DEBUGGING / DEVELOPMENT HELPERS
  // ==========================================================================

  /// Get current state as human-readable string (for logging/debugging)
  String get stateDescription => _currentState.description;

  /// Get complete state snapshot for debugging
  Map<String, dynamic> getStateSnapshot() {
    return {
      'current_state': _currentState.toString(),
      'has_candidate': _candidateTerms != null,
      'candidate_complete': isCandidateComplete,
      'has_confirmed': _confirmedTerms != null,
      'has_result': _calculationResult != null,
      'has_pdf': _generatedPDF != null,
      'is_loading': _isLoading,
      'has_error': _errorMessage != null,
      'error_message': _errorMessage,
    };
  }
}

/// ============================================================================
/// APPLICATION WORKFLOW STATES (Enum)
/// ============================================================================
/// Represents the current position in the workflow.
/// State transitions are ONE-WAY and FORWARD-ONLY (no backwards transitions).
/// ============================================================================
enum AppState {
  /// No data yet - waiting for loan document input
  idle,

  /// AI has extracted data (UNTRUSTED) - waiting for human validation
  aiExtracted,

  /// Human has validated data (TRUSTED) - ready for calculation
  humanValidated,

  /// Math engine has calculated TRUE APR - ready for PDF generation
  calculated,

  /// PDF evidence document has been generated - ready for submission
  pdfGenerated,
}

/// Extension to add description to AppState enum
extension AppStateExtension on AppState {
  String get description {
    switch (this) {
      case AppState.idle:
        return 'Idle - No data';
      case AppState.aiExtracted:
        return 'AI Extracted - Awaiting validation';
      case AppState.humanValidated:
        return 'Human Validated - Ready for calculation';
      case AppState.calculated:
        return 'Calculated - Ready for PDF generation';
      case AppState.pdfGenerated:
        return 'PDF Generated - Ready for submission';
    }
  }
}