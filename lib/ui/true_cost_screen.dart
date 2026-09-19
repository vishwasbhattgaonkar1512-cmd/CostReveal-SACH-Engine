import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/app_state.dart';
import 'rbi_draft_screen.dart';

class TrueCostScreen extends StatefulWidget {
  const TrueCostScreen({super.key});

  @override
  State<TrueCostScreen> createState() => _TrueCostScreenState();
}

class _TrueCostScreenState extends State<TrueCostScreen>
    with TickerProviderStateMixin {
  late AnimationController _greenController;
  late AnimationController _redController;
  late Animation<double> _greenProgress;
  late Animation<double> _redProgress;

  bool _showRed = false;

  @override
  void initState() {
    super.initState();

    // Green line draws over 1s
    _greenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _greenProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _greenController, curve: Curves.easeOut),
    );

    // Red line draws over 1.2s — starts after 0.5s pause
    _redController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _redProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _redController, curve: Curves.easeOut),
    );

    // Sequence: green → pause 0.5s → red
    _greenController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showRed = true);
          _redController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _greenController.dispose();
    _redController.dispose();
    super.dispose();
  }

  List<FlSpot> _trimSpots(List<FlSpot> spots, double progress) {
    if (spots.isEmpty || progress <= 0) return [spots.first];
    final cutIndex = (spots.length * progress).floor();
    return spots.sublist(0, cutIndex.clamp(1, spots.length));
  }

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
    double actualAccumulated = terms.upfrontProcessingFee;

    greenSpots.add(FlSpot(0, advertisedAccumulated));
    redSpots.add(FlSpot(0, actualAccumulated));

    for (int m = 1; m <= terms.tenureMonths; m++) {
      advertisedAccumulated += advertisedInstalment;
      actualAccumulated += calc.monthlyInstalment;
      greenSpots.add(FlSpot(m.toDouble(), advertisedAccumulated));
      redSpots.add(FlSpot(m.toDouble(), actualAccumulated));
    }

    final double schoolFeesMonths = calc.totalHiddenCost / 3200;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(title: const Text('Asli Sach (True Cost)')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aap par ${calc.trueApr.toStringAsFixed(1)}% ka bojh hai.',
              style: const TextStyle(
                  fontSize: 26,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '₹${calc.totalHiddenCost.toStringAsFixed(0)} gayab',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Staggered animated chart
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([_greenProgress, _redProgress]),
                builder: (context, _) {
                  final visibleGreen =
                      _trimSpots(greenSpots, _greenProgress.value);
                  final visibleRed = _showRed
                      ? _trimSpots(redSpots, _redProgress.value)
                      : <FlSpot>[];

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      minX: 0,
                      maxX: terms.tenureMonths.toDouble(),
                      minY: 0,
                      maxY: redSpots.last.y * 1.1,
                      lineBarsData: [
                        // Green: Jo Bataya — SOLID line
                        LineChartBarData(
                          spots: visibleGreen,
                          isCurved: false,
                          color: const Color(0xFF10B981),
                          barWidth: 5,
                          dotData: FlDotData(show: false),
                          dashArray: null, // Solid = colorblind cue 1
                        ),
                        // Red: Asli Sach — DASHED line (colorblind cue 2)
                        if (visibleRed.isNotEmpty)
                          LineChartBarData(
                            spots: visibleRed,
                            isCurved: false,
                            color: const Color(0xFFDC2626),
                            barWidth: 5,
                            dotData: FlDotData(show: false),
                            dashArray: [8, 4], // Dashed = redundant cue for colorblind users
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Colorblind-safe legend (icon + label + line style)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(const Color(0xFF10B981), 'Jo Bataya', isDashed: false),
                const SizedBox(width: 24),
                _buildLegend(const Color(0xFFDC2626), 'Asli Sach', isDashed: true),
              ],
            ),

            const SizedBox(height: 24),

            // Emotional bomb at the bottom
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You are paying ₹${calc.totalHiddenCost.toStringAsFixed(0)} extra.\nThat is ${schoolFeesMonths.toStringAsFixed(1)} months of your child\'s school fees.',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RbiDraftScreen()),
                );
              },
              child: const Text('RBI Draft Dekho →'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text, {required bool isDashed}) {
    return Row(
      children: [
        CustomPaint(
          size: const Size(32, 4),
          painter: _LineLegendPainter(color: color, isDashed: isDashed),
        ),
        const SizedBox(width: 8),
        Text(text,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _LineLegendPainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  _LineLegendPainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    if (!isDashed) {
      canvas.drawLine(Offset(0, size.height / 2),
          Offset(size.width, size.height / 2), paint);
    } else {
      double x = 0;
      bool drawing = true;
      while (x < size.width) {
        final end = (x + 6).clamp(0, size.width).toDouble();
        if (drawing) {
          canvas.drawLine(Offset(x, size.height / 2),
              Offset(end, size.height / 2), paint);
        }
        x += 8;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
