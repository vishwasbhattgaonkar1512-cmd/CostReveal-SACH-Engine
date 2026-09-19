import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'true_cost_screen.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  final _principalCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();
  final _flatRateCtrl = TextEditingController();
  final _procFeeCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();

  final Map<String, bool> _confirmedFields = {
    'principal': false,
    'months': false,
    'rate': false,
    'fee': false,
    'insurance': false,
  };

  bool get _allConfirmed => !_confirmedFields.values.any((element) => element == false);
  int get _confirmedCount => _confirmedFields.values.where((element) => element == true).length;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Kripya numbers check karein')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Confirm details from document',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '$_confirmedCount/5 confirmed',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: _allConfirmed ? const Color(0xFF10B981) : Colors.black54
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildValidationCard(
            label: 'Principal Amount',
            controller: _principalCtrl,
            fieldKey: 'principal',
            onChanged: (val) => appState.updateCandidate(principal: double.tryParse(val)),
          ),
          _buildValidationCard(
            label: 'Tenure (Months)',
            controller: _monthsCtrl,
            fieldKey: 'months',
            onChanged: (val) => appState.updateCandidate(months: int.tryParse(val)),
          ),
          _buildValidationCard(
            label: 'Advertised Flat Rate (%)',
            controller: _flatRateCtrl,
            fieldKey: 'rate',
            onChanged: (val) => appState.updateCandidate(flatRate: double.tryParse(val)),
          ),
          _buildValidationCard(
            label: 'Upfront Processing Fee',
            controller: _procFeeCtrl,
            fieldKey: 'fee',
            onChanged: (val) => appState.updateCandidate(procFee: double.tryParse(val)),
          ),
          _buildValidationCard(
            label: 'Monthly Insurance Premium',
            controller: _insuranceCtrl,
            fieldKey: 'insurance',
            onChanged: (val) => appState.updateCandidate(insurance: double.tryParse(val)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _allConfirmed
                ? () {
                    appState.confirmTerms();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrueCostScreen()),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _allConfirmed ? const Color(0xFF10B981) : Colors.grey,
            ),
            child: const Text('Asli Sach Dekhein'), // "See the real truth"
          )
        ],
      ),
    );
  }

  Widget _buildValidationCard({
    required String label,
    required TextEditingController controller,
    required String fieldKey,
    required Function(String) onChanged,
  }) {
    final isConfirmed = _confirmedFields[fieldKey] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: isConfirmed ? Colors.grey[100] : Colors.white,
                ),
                keyboardType: TextInputType.number,
                enabled: !isConfirmed,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _confirmedFields[fieldKey] = !isConfirmed;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isConfirmed ? const Color(0xFF10B981) : Colors.white, // Green if confirmed
                  border: Border.all(
                    color: isConfirmed ? const Color(0xFF10B981) : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check,
                  color: isConfirmed ? Colors.white : Colors.grey,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
