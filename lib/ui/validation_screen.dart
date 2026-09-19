import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'true_cost_screen.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({Key? key}) : super(key: key);

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  final _principalCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();
  final _flatRateCtrl = TextEditingController();
  final _procFeeCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Validate & Confirm')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _principalCtrl,
            decoration: const InputDecoration(labelText: 'Principal Amount'),
            keyboardType: TextInputType.number,
            onChanged: (val) => appState.updateCandidate(principal: double.tryParse(val)),
          ),
          TextField(
            controller: _monthsCtrl,
            decoration: const InputDecoration(labelText: 'Tenure (Months)'),
            keyboardType: TextInputType.number,
            onChanged: (val) => appState.updateCandidate(months: int.tryParse(val)),
          ),
          TextField(
            controller: _flatRateCtrl,
            decoration: const InputDecoration(labelText: 'Advertised Flat Rate (%)'),
            keyboardType: TextInputType.number,
            onChanged: (val) => appState.updateCandidate(flatRate: double.tryParse(val)),
          ),
          TextField(
            controller: _procFeeCtrl,
            decoration: const InputDecoration(labelText: 'Upfront Processing Fee'),
            keyboardType: TextInputType.number,
            onChanged: (val) => appState.updateCandidate(procFee: double.tryParse(val)),
          ),
          TextField(
            controller: _insuranceCtrl,
            decoration: const InputDecoration(labelText: 'Monthly Insurance Premium'),
            keyboardType: TextInputType.number,
            onChanged: (val) => appState.updateCandidate(insurance: double.tryParse(val)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              appState.confirmTerms();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrueCostScreen()),
              );
            },
            child: const Text('Confirm'),
          )
        ],
      ),
    );
  }
}
