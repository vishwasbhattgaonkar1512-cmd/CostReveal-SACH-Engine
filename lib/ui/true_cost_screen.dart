import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../utils/formatters.dart';
import 'rbi_draft_screen.dart';

class TrueCostScreen extends StatefulWidget {
  const TrueCostScreen({super.key});

  @override
  State<TrueCostScreen> createState() => _TrueCostScreenState();
}

class _TrueCostScreenState extends State<TrueCostScreen>
    with TickerProviderStateMixin {
  late AnimationController _greenCtrl;
  late AnimationController _redCtrl;
  late Animation<double> _greenProg;
  late Animation<double> _redProg;
  bool _showRed = false;

  @override
  void initState() {
    super.initState();

    // Green draws over 1 second
    _greenCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _greenProg  = CurvedAnimation(parent: _greenCtrl, curve: Curves.easeOut);

    // Red draws over 1.2 seconds after a 500ms pause
    _redCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _redProg   = CurvedAnimation(parent: _redCtrl, curve: Curves.easeOut);

    _greenCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // HEAVY HAPTIC THUD when the truth is revealed (Premium tactility)
          HapticFeedback.heavyImpact();
          setState(() => _showRed = true);
          _redCtrl.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _greenCtrl.dispose();
    _redCtrl.dispose();
    super.dispose();
  }

  List<FlSpot> _trim(List<FlSpot> spots, double progress) {
    if (spots.isEmpty || progress <= 0) return [spots.first];
    final cut = (spots.length * progress).floor().clamp(1, spots.length);
    return spots.sublist(0, cut);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppProvider>(context);
    final terms = state.confirmedTerms;
    final calc  = state.calculationResult;

    if (terms == null || calc == null) {
      return const Scaffold(body: Center(child: Text('Error: No data')));
    }

    final advertisedInstalment = terms.principal_amount / terms.tenure_months +
        (terms.principal_amount * (terms.advertised_flat_rate / 100) / 12);

    final List<FlSpot> greenSpots = [];
    final List<FlSpot> redSpots   = [];

    double greenAcc = 0;
    double redAcc   = terms.upfront_processing_fee; // fee taken on day 0

    greenSpots.add(FlSpot(0, greenAcc));
    redSpots.add(FlSpot(0, redAcc));

    for (int m = 1; m <= terms.tenure_months; m++) {
      greenAcc += advertisedInstalment;
      redAcc   += calc.actual_monthly_outflow;
      greenSpots.add(FlSpot(m.toDouble(), greenAcc));
      redSpots.add(FlSpot(m.toDouble(), redAcc));
    }

    final double maxY           = redSpots.last.y * 1.1;
    final double schoolMonths   = calc.total_hidden_cost / 3200;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Asli Sach')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero stat
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppTheme.cardPadding),
              decoration: AppTheme.heroStatDecoration(AppTheme.red),
              child: Column(
                children: [
                  Text(
                    '${calc.true_apr.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 40, // Massive for hero stat
                      fontWeight: AppTheme.numberWeight,
                      color: AppTheme.white,
                      letterSpacing: -1.5, // Premium sleek kerning
                    ),
                  ),
                  const Text(
                    'Aap par itna bojh hai  (Effective Annualized Cost)',
                    style: TextStyle(
                      fontSize: AppTheme.bodyMin,
                      color: AppTheme.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Chart (HERO of this screen)
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([_greenProg, _redProg]),
                builder: (context, _) {
                  final vGreen = _trim(greenSpots, _greenProg.value);
                  final vRed   = _showRed ? _trim(redSpots, _redProg.value) : <FlSpot>[];

                  return LineChart(LineChartData(
                    minX: 0, maxX: terms.tenure_months.toDouble(),
                    minY: 0, maxY: maxY,
                    gridData:   FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      // Index 0: Jo Bataya - SOLID, green
                      LineChartBarData(
                        spots:    vGreen,
                        isCurved: false,
                        color:    AppTheme.green,
                        barWidth: 5,
                        dotData:  FlDotData(show: false),
                        dashArray: null,
                      ),
                      // Index 1: Asli Sach - DASHED, red
                      if (vRed.isNotEmpty)
                        LineChartBarData(
                          spots:    vRed,
                          isCurved: false,
                          color:    AppTheme.red,
                          barWidth: 5,
                          dotData:  FlDotData(show: false),
                          dashArray: [8, 4],
                        ),
                    ],
                    // PREMIUM: Fill the gap between the two lines with light red to represent "stolen money"
                    betweenBarsData: vRed.isNotEmpty
                        ? [
                            BetweenBarsData(
                              fromIndex: 0,
                              toIndex: 1,
                              color: AppTheme.red.withValues(alpha: 0.12),
                            )
                          ]
                        : [],
                  ));
                },
              ),
            ),

            const SizedBox(height: 8),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(AppTheme.green, 'Jo Bataya  (Promised)', dashed: false),
                const SizedBox(width: 24),
                _legendItem(AppTheme.red,   'Asli Sach  (True Cost)', dashed: true),
              ],
            ),

            const SizedBox(height: 24), // Gestalt whitespace before emotional bomb

            // Emotional bomb
            Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: AppTheme.cardDecoration(borderColor: AppTheme.red),
              child: Column(
                children: [
                  Text(
                    '₹${Formatters.formatAmountWithoutSymbol(calc.total_hidden_cost)} gayab ho gaye',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: AppTheme.numberWeight,
                      color: AppTheme.red,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '₹${Formatters.formatAmountWithoutSymbol(calc.total_hidden_cost)} disappeared',
                    style: const TextStyle(fontSize: AppTheme.labelSize, color: AppTheme.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Yani ${schoolMonths.toStringAsFixed(1)} mahine ki school fees',
                    style: const TextStyle(fontSize: AppTheme.bodyMin, color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '= ${schoolMonths.toStringAsFixed(1)} months of school fees (NSSO benchmark)',
                    style: const TextStyle(fontSize: AppTheme.labelSize, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('RBI Draft Generate Karein'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, {required bool dashed}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 4,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed
                ? Border(
                    bottom: BorderSide(
                      color: color,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  )
                : null,
          ),
          child: dashed
              ? CustomPaint(
                  painter: _LegendLinePainter(color),
                  size: const Size(24, 4),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.labelSize,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  final Color color;
  _LegendLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const double dashWidth = 6;
    const double dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
