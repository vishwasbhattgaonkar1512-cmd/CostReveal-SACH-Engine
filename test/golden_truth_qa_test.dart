import 'package:flutter_test/flutter_test.dart';
import 'package:costreveal_sach_engine/engine/math_engine.dart';
import 'package:costreveal_sach_engine/models/loan_terms.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  test('Golden Truth QA', () {
    final cases = [
      {"id": "C01", "principal": 100000.0, "tenure": 12, "rate": 10.0, "fee": 0.0, "ins": 0.0},
      {"id": "C02", "principal": 50000.0, "tenure": 24, "rate": 15.0, "fee": 0.0, "ins": 0.0},
      {"id": "C03", "principal": 200000.0, "tenure": 12, "rate": 12.0, "fee": 5000.0, "ins": 0.0},
      {"id": "C04", "principal": 150000.0, "tenure": 18, "rate": 14.0, "fee": 0.0, "ins": 1000.0},
      {"id": "C05", "principal": 100000.0, "tenure": 12, "rate": 18.0, "fee": 3000.0, "ins": 500.0},
      {"id": "C06", "principal": 100000.0, "tenure": 12, "rate": 0.0, "fee": 4000.0, "ins": 0.0},
      {"id": "C07", "principal": 10000.0, "tenure": 6, "rate": 24.0, "fee": 1000.0, "ins": 200.0},
      {"id": "C08", "principal": 500000.0, "tenure": 36, "rate": 9.0, "fee": 10000.0, "ins": 0.0},
      {"id": "C09", "principal": 50000.0, "tenure": 60, "rate": 11.0, "fee": 2000.0, "ins": 100.0},
      {"id": "C10", "principal": 75000.0, "tenure": 12, "rate": 30.0, "fee": 0.0, "ins": 0.0}
    ];

    final engine = MathEngine();
    final results = [];

    for (final c in cases) {
      final terms = ConfirmedLoanTerms.fromValues(
        principal_amount: c["principal"] as double,
        tenure_months: c["tenure"] as int,
        advertised_flat_rate: c["rate"] as double,
        upfront_processing_fee: c["fee"] as double,
        monthly_insurance_premium: c["ins"] as double,
      );

      final res = engine.exposeTheTruth(terms);
      final breakdown = engine.generateDetailedBreakdown(terms);
      
      final monthly_irr_percent = breakdown['monthly_irr_percent'] as double;
      final monthly_irr = monthly_irr_percent / 100.0; // decimal

      results.add({
        "id": c["id"],
        "true_apr": res.true_apr,
        "hidden_cost": res.total_hidden_cost,
        "monthly_irr": monthly_irr
      });
    }

    final out = File('m4_evidence/flutter_app_results.json');
    out.writeAsStringSync(jsonEncode(results));
  });
}
