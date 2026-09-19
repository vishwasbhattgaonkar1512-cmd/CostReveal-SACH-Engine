import 'package:flutter/material.dart';
import '../models/loan_terms.dart';
import '../engine/math_engine.dart';

class AppState extends ChangeNotifier {
  CandidateLoanTerms candidateTerms = CandidateLoanTerms();
  ConfirmedLoanTerms? confirmedTerms;
  CalculationResult? calcResult;

  void updateCandidate({
    double? principal,
    int? months,
    double? flatRate,
    double? procFee,
    double? insurance,
  }) {
    if (principal != null) candidateTerms.principalAmount = principal;
    if (months != null) candidateTerms.tenureMonths = months;
    if (flatRate != null) candidateTerms.advertisedFlatRate = flatRate;
    if (procFee != null) candidateTerms.upfrontProcessingFee = procFee;
    if (insurance != null) candidateTerms.monthlyInsurancePremium = insurance;
    notifyListeners();
  }

  void confirmTerms() {
    confirmedTerms = ConfirmedLoanTerms(
      principalAmount: candidateTerms.principalAmount ?? 0.0,
      tenureMonths: candidateTerms.tenureMonths ?? 0,
      advertisedFlatRate: candidateTerms.advertisedFlatRate ?? 0.0,
      upfrontProcessingFee: candidateTerms.upfrontProcessingFee ?? 0.0,
      monthlyInsurancePremium: candidateTerms.monthlyInsurancePremium ?? 0.0,
    );
    calcResult = MathEngine.calculate(confirmedTerms!);
    notifyListeners();
  }
}
