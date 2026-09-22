import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:costreveal_sach_engine/state/app_state.dart';
import 'package:costreveal_sach_engine/models/loan_terms.dart';
import 'package:costreveal_sach_engine/ui/rbi_draft_screen.dart';

void main() {
  testWidgets('RbiDraftScreen displays actual values instead of placeholders', (WidgetTester tester) async {
    final appState = AppProvider();
    
    // Set candidate terms (AI extracted)
    appState.updateCandidateTerms(const CandidateLoanTerms(
      principal_amount: 100000.0,
      tenure_months: 12,
      advertised_flat_rate: 24.0,
      upfront_processing_fee: 2000.0,
      monthly_insurance_premium: 500.0,
    ));

    // Confirm all terms (human validated)
    appState.validateAndConfirmTerms();
    
    // Calculate True APR (mathematics decides)
    appState.calculateTrueAPR();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: appState,
        child: const MaterialApp(
          home: RbiDraftScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify actual values are rendered
    expect(find.textContaining('1,00,000'), findsWidgets);
    expect(find.textContaining('12 months'), findsWidgets);
    expect(find.textContaining('24% p.a.'), findsOneWidget);
    expect(find.textContaining('2,000'), findsWidgets);
    expect(find.textContaining('500'), findsWidgets);
    expect(find.textContaining('55.7%'), findsOneWidget); // Math engine expected result
    expect(find.textContaining('18000.00'), findsWidgets); // Math engine expected hidden cost in trace

    // Verify placeholders are NOT rendered
    expect(find.textContaining('[auto-filled]'), findsNothing);
    expect(find.textContaining('[X]'), findsNothing);
  });
}
