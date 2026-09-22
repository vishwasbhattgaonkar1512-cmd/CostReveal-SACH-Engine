import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/loan_terms.dart';
import 'true_cost_screen.dart';
import 'widgets/bouncing_touch.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  final _principalCtrl  = TextEditingController();
  final _monthsCtrl     = TextEditingController();
  final _flatRateCtrl   = TextEditingController();
  final _procFeeCtrl    = TextEditingController();
  final _insuranceCtrl  = TextEditingController();

  final Map<String, bool> _confirmed = {
    'principal': false,
    'months':    false,
    'rate':      false,
    'fee':       false,
    'insurance': false,
  };

  bool get _allConfirmed   => _confirmed.values.every((v) => v);
  int  get _confirmedCount => _confirmed.values.where((v) => v).length;
  int  get _totalFields    => _confirmed.length;

  String? _getFieldError(String value) {
    if (value.isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null) return 'अमान्य संख्या (Invalid number)';
    if (parsed < 0) return 'नकारात्मक नहीं हो सकता (No negatives)';
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final candidate = Provider.of<AppProvider>(context, listen: false).candidateTerms;
      if (candidate != null) {
        if (candidate.principal_amount != null) {
          _principalCtrl.text = candidate.principal_amount!.toString().replaceAll(RegExp(r'\.0$'), '');
        }
        if (candidate.tenure_months != null) {
          _monthsCtrl.text = candidate.tenure_months!.toString();
        }
        if (candidate.advertised_flat_rate != null) {
          _flatRateCtrl.text = candidate.advertised_flat_rate!.toString().replaceAll(RegExp(r'\.0$'), '');
        }
        if (candidate.upfront_processing_fee != null) {
          _procFeeCtrl.text = candidate.upfront_processing_fee!.toString().replaceAll(RegExp(r'\.0$'), '');
        }
        if (candidate.monthly_insurance_premium != null) {
          _insuranceCtrl.text = candidate.monthly_insurance_premium!.toString().replaceAll(RegExp(r'\.0$'), '');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('संख्याएँ जाँचें  (Verify Numbers)')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        children: [
          // ── Progress header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding, vertical: 14),
            decoration: AppTheme.cardDecoration(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'कृपया नंबर्स चेक करें',
                  style: TextStyle(
                    fontSize: AppTheme.bodyMin,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '$_confirmedCount/$_totalFields',
                  style: TextStyle(
                    fontSize: AppTheme.subheadline,
                    fontWeight: AppTheme.numberWeight,
                    color: _allConfirmed ? AppTheme.green : AppTheme.navy,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _confirmedCount / _totalFields,
              minHeight: 8,
              color: _allConfirmed ? AppTheme.green : AppTheme.navy,
              backgroundColor: AppTheme.border,
            ),
          ),

          const SizedBox(height: 32), // Expanded whitespace separating header from cards

          _buildCard(
            label:       'लोन की रकम',
            sublabel:    'Principal Amount',
            controller:  _principalCtrl,
            fieldKey:    'principal',
            onChanged:   (v) => appState.updateCandidateTerms((appState.candidateTerms ?? CandidateLoanTerms()).copyWith(principal_amount: double.tryParse(v))),
          ),
          _buildCard(
            label:       'कितने महीने का लोन है?',
            sublabel:    'Tenure in Months',
            controller:  _monthsCtrl,
            fieldKey:    'months',
            onChanged:   (v) => appState.updateCandidateTerms((appState.candidateTerms ?? CandidateLoanTerms()).copyWith(tenure_months: int.tryParse(v))),
          ),
          _buildCard(
            label:       'बताई गई ब्याज दर',
            sublabel:    'Advertised Flat Rate (%)',
            controller:  _flatRateCtrl,
            fieldKey:    'rate',
            onChanged:   (v) => appState.updateCandidateTerms((appState.candidateTerms ?? CandidateLoanTerms()).copyWith(advertised_flat_rate: double.tryParse(v))),
          ),
          _buildCard(
            label:       'प्रोसेसिंग फीस',
            sublabel:    'Upfront Processing Fee',
            controller:  _procFeeCtrl,
            fieldKey:    'fee',
            onChanged:   (v) => appState.updateCandidateTerms((appState.candidateTerms ?? CandidateLoanTerms()).copyWith(upfront_processing_fee: double.tryParse(v))),
          ),
          _buildCard(
            label:       'हर महीने का बीमा',
            sublabel:    'Monthly Insurance Premium',
            controller:  _insuranceCtrl,
            fieldKey:    'insurance',
            onChanged:   (v) => appState.updateCandidateTerms((appState.candidateTerms ?? CandidateLoanTerms()).copyWith(monthly_insurance_premium: double.tryParse(v))),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _allConfirmed
                ? () {
                    if (appState.validateAndConfirmTerms()) {
                      if (appState.calculateTrueAPR()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TrueCostScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appState.errorMessage ?? 'Calculation failed')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(appState.errorMessage ?? 'Validation failed'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      // Uncheck all boxes if validation failed so user can fix them
                      setState(() {
                        _confirmed.updateAll((key, value) => false);
                      });
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _allConfirmed ? AppTheme.green : AppTheme.border,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('✓ जानकारी सही है, आगे बढ़ें'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String label,
    required String sublabel,
    required TextEditingController controller,
    required String fieldKey,
    required Function(String) onChanged,
  }) {
    final confirmed = _confirmed[fieldKey] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: AppTheme.cardDecoration(
          borderColor: confirmed ? AppTheme.green : AppTheme.border,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTheme.bodyMin,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2), // Tighten gap for Gestalt grouping
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: AppTheme.labelSize,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      enabled: !confirmed,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      style: TextStyle(
                        fontSize: AppTheme.subheadline,
                        fontWeight: AppTheme.numberWeight,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5, // Premium sleek numbers
                      ),
                      decoration: InputDecoration(
                        fillColor: confirmed ? const Color(0xFFF3F4F6) : AppTheme.white,
                        hintText: confirmed ? '✓ सत्यापित' : '✎ बदलें',
                        errorText: _getFieldError(controller.text),
                      ),
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tactile bouncing confirm target
              BouncingTouch(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _confirmed[fieldKey] = !confirmed);
                },
                child: Container(
                  width: AppTheme.minTapTarget,
                  height: AppTheme.minTapTarget,
                  decoration: BoxDecoration(
                    color: confirmed ? AppTheme.green : AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(
                      color: confirmed ? AppTheme.green : AppTheme.border,
                      width: AppTheme.cardBorderWidth,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: confirmed ? AppTheme.white : AppTheme.border,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

