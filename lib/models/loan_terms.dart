class CandidateLoanTerms {
  double? principalAmount;
  int? tenureMonths;
  double? advertisedFlatRate;
  double? upfrontProcessingFee;
  double? monthlyInsurancePremium;

  CandidateLoanTerms({
    this.principalAmount,
    this.tenureMonths,
    this.advertisedFlatRate,
    this.upfrontProcessingFee,
    this.monthlyInsurancePremium,
  });
}

class ConfirmedLoanTerms {
  final double principalAmount;
  final int tenureMonths;
  final double advertisedFlatRate;
  final double upfrontProcessingFee;
  final double monthlyInsurancePremium;

  ConfirmedLoanTerms({
    required this.principalAmount,
    required this.tenureMonths,
    required this.advertisedFlatRate,
    required this.upfrontProcessingFee,
    required this.monthlyInsurancePremium,
  });
}
