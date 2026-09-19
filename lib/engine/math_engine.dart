import '../models/loan_terms.dart';

class CalculationResult {
  final double trueApr;
  final double totalHiddenCost;
  final double monthlyInstalment;

  CalculationResult({
    required this.trueApr,
    required this.totalHiddenCost,
    required this.monthlyInstalment,
  });
}

class MathEngine {
  static CalculationResult calculate(ConfirmedLoanTerms terms) {
    // Simple mock logic for midnight goal.
    // In reality, this would be an XIRR calculation.
    
    // Monthly interest based on flat rate:
    double totalInterest = terms.principalAmount * (terms.advertisedFlatRate / 100) * (terms.tenureMonths / 12);
    double monthlyInstalment = (terms.principalAmount + totalInterest) / terms.tenureMonths;
    monthlyInstalment += terms.monthlyInsurancePremium;

    // Total actual outflow = (monthlyInstalment * tenureMonths) + upfrontProcessingFee
    double totalOutflow = (monthlyInstalment * terms.tenureMonths) + terms.upfrontProcessingFee;
    
    // Hidden Cost
    double totalHiddenCost = totalOutflow - terms.principalAmount;

    // Mock APR (just a dummy multiplier for now until XIRR is built)
    double trueApr = terms.advertisedFlatRate * 1.8;

    return CalculationResult(
      trueApr: trueApr,
      totalHiddenCost: totalHiddenCost,
      monthlyInstalment: monthlyInstalment,
    );
  }
}
