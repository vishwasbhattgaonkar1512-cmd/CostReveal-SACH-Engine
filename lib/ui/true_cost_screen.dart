import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/app_state.dart';

class TrueCostScreen extends StatelessWidget {
  const TrueCostScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final terms = state.confirmedTerms;
    final calc = state.calcResult;

    if (terms == null || calc == null) {
      return const Scaffold(body: Center(child: Text('No data.')));
    }

    final advertisedInstalment = terms.principalAmount / terms.tenureMonths + 
      (terms.principalAmount * (terms.advertisedFlatRate / 100) / 12);
    
    List<FlSpot> greenSpots = [];
    List<FlSpot> redSpots = [];
    
    double advertisedAccumulated = 0;
    double actualAccumulated = terms.upfrontProcessingFee; // Day 0 outflow

    greenSpots.add(FlSpot(0, advertisedAccumulated));
    redSpots.add(FlSpot(0, actualAccumulated));

    for (int m = 1; m <= terms.tenureMonths; m++) {
      advertisedAccumulated += advertisedInstalment;
      actualAccumulated += calc.monthlyInstalment;
      greenSpots.add(FlSpot(m.toDouble(), advertisedAccumulated));
      redSpots.add(FlSpot(m.toDouble(), actualAccumulated));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('The Crime Scene (True Cost)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('True APR: ${calc.trueApr.toStringAsFixed(2)}%', 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total Hidden Cost: ₹${calc.totalHiddenCost.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),
            Expanded(
              child: LineChart(
                LineChartData(
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: greenSpots,
                      isCurved: false,
                      color: Colors.green,
                      barWidth: 3,
                    ),
                    LineChartBarData(
                      spots: redSpots,
                      isCurved: false,
                      color: Colors.red,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Green: Advertised Cost | Red: Actual Outflow'),
          ],
        ),
      ),
    );
  }
}
