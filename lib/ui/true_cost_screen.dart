import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
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
  bool _evidenceExpanded = false;

  @override
  void initState() {
    super.initState();
    _greenCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _greenProg  = CurvedAnimation(parent: _greenCtrl, curve: Curves.easeOut);
    _redCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _redProg   = CurvedAnimation(parent: _redCtrl, curve: Curves.easeOut);

    _greenCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
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
    final state = context.watch<AppProvider>();
    final terms = state.confirmedTerms;
    final calc  = state.calculationResult;

    if (terms == null || calc == null) {
      return const Scaffold(body: Center(child: Text('à¤•à¥‹à¤ˆ à¤¡à¥‡à¤Ÿà¤¾ à¤¨à¤¹à¥€à¤‚à¥¤')));
    }

    final advertisedInstalment = terms.principal_amount / terms.tenure_months +
        (terms.principal_amount * (terms.advertised_flat_rate / 100) / 12);

    final List<FlSpot> greenSpots = [];
    final List<FlSpot> redSpots   = [];
    double greenAcc = 0;
    double redAcc   = terms.upfront_processing_fee;

    greenSpots.add(FlSpot(0, greenAcc));
    redSpots.add(FlSpot(0, redAcc));

    for (int m = 1; m <= terms.tenure_months; m++) {
      greenAcc += advertisedInstalment;
      redAcc   += calc.actual_monthly_outflow;
      greenSpots.add(FlSpot(m.toDouble(), greenAcc));
      redSpots.add(FlSpot(m.toDouble(), redAcc));
    }

    final double maxY        = redSpots.last.y * 1.1;
    final double schoolMonths = calc.total_hidden_cost / 3200;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('à¤…à¤¸à¤²à¥€ à¤¸à¤š  (Asli Sach)')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        children: [
          // â”€â”€ Hero stat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppTheme.cardPadding),
            decoration: AppTheme.heroStatDecoration(AppTheme.red),
            child: Column(
              children: [
                Text(
                  '${calc.true_apr.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: AppTheme.numberWeight,
                    color: AppTheme.white,
                    letterSpacing: -1.5,
                  ),
                ),
                const Text(
                  'à¤†à¤ª à¤ªà¤° à¤‡à¤¤à¤¨à¤¾ à¤¬à¥‹à¤ à¤¹à¥ˆ  (True APR)',
                  style: TextStyle(fontSize: AppTheme.bodyMin, color: AppTheme.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // â”€â”€ Chart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const Text(
            'à¤†à¤ªà¤•à¥‹ à¤•à¥à¤² à¤•à¤¿à¤¤à¤¨à¤¾ à¤¦à¥‡à¤¨à¤¾ à¤¹à¥‹à¤—à¤¾?  (Total repayment over time)',
            style: TextStyle(fontSize: AppTheme.labelSize, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
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
                    LineChartBarData(
                      spots: vGreen, isCurved: false,
                      color: AppTheme.green, barWidth: 5,
                      dotData: FlDotData(show: false), dashArray: null,
                    ),
                    if (vRed.isNotEmpty)
                      LineChartBarData(
                        spots: vRed, isCurved: false,
                        color: AppTheme.red, barWidth: 5,
                        dotData: FlDotData(show: false), dashArray: [8, 4],
                      ),
                  ],
                  betweenBarsData: vRed.isNotEmpty
                      ? [BetweenBarsData(
                          fromIndex: 0, toIndex: 1,
                          color: AppTheme.red.withValues(alpha: 0.12),
                        )]
                      : [],
                ));
              },
            ),
          ),

          const SizedBox(height: 8),

          // â”€â”€ Legend â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(AppTheme.green, 'à¤œà¥‹ à¤¬à¤¤à¤¾à¤¯à¤¾ à¤¥à¤¾  (Promised)', dashed: false),
              const SizedBox(width: 24),
              _legendItem(AppTheme.red,   'à¤…à¤¸à¤²à¥€ à¤¸à¤š  (True Cost)', dashed: true),
            ],
          ),

          const SizedBox(height: 24),

          // â”€â”€ Emotional bomb â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: AppTheme.cardDecoration(borderColor: AppTheme.red),
            child: Column(
              children: [
                Text(
                  'â‚¹${calc.total_hidden_cost.toStringAsFixed(0)} à¤•à¤¾ à¤¨à¥à¤•à¤¸à¤¾à¤¨',
                  style: const TextStyle(
                    fontSize: 24, fontWeight: AppTheme.numberWeight,
                    color: AppTheme.red, letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Loss of â‚¹${calc.total_hidden_cost.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: AppTheme.labelSize, color: AppTheme.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'à¤®à¤¤à¤²à¤¬ ${schoolMonths.toStringAsFixed(1)} à¤®à¤¹à¥€à¤¨à¥‡ à¤•à¥€ à¤¸à¥à¤•à¥‚à¤² à¤«à¥€à¤¸!',
                  style: const TextStyle(fontSize: AppTheme.bodyMin, color: AppTheme.textPrimary),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '= ${schoolMonths.toStringAsFixed(1)} months of school fees (NSSO benchmark â‚¹3,200)',
                  style: const TextStyle(fontSize: AppTheme.labelSize, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // â”€â”€ Task 5-C: "What Changed the Cost?" Cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const Text(
            'à¤®à¤¹à¤à¤—à¤¾ à¤•à¥à¤¯à¥‹à¤‚ à¤¹à¥à¤†?  (What Changed the Cost?)',
            style: TextStyle(fontSize: AppTheme.bodyMin, fontWeight: FontWeight.bold, color: AppTheme.navy),
          ),
          const SizedBox(height: 12),
          
          _costChangeCard(
            title: 'à¤«à¥à¤²à¥ˆà¤Ÿ à¤°à¥‡à¤Ÿ (Flat Rate)',
            subtitle: 'Interest charged on full amount, not remaining balance.',
            impact: 'Double interest burden',
            icon: Icons.percent_rounded,
          ),
          if (terms.upfront_processing_fee > 0)
            _costChangeCard(
              title: 'à¤ªà¥à¤°à¥‹à¤¸à¥‡à¤¸à¤¿à¤‚à¤— à¤«à¥€à¤¸ (Processing Fee)',
              subtitle: 'â‚¹${terms.upfront_processing_fee.toStringAsFixed(0)} deducted upfront before you even get the money.',
              impact: 'Reduces money in hand',
              icon: Icons.money_off_rounded,
            ),
          if (terms.monthly_insurance_premium > 0)
            _costChangeCard(
              title: 'à¤¬à¥€à¤®à¤¾ (Insurance)',
              subtitle: 'â‚¹${terms.monthly_insurance_premium.toStringAsFixed(0)} extra taken from you every month.',
              impact: 'Increases EMI artificially',
              icon: Icons.health_and_safety_rounded,
            ),

          const SizedBox(height: 16),

          // â”€â”€ Task 5-B: Cost-Affecting Patterns â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: AppTheme.cardDecoration(borderColor: const Color(0xFFF59E0B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'à¤²à¥‹à¤¨ à¤•à¥‹ à¤®à¤¹à¤à¤—à¤¾ à¤¬à¤¨à¤¾à¤¨à¥‡ à¤µà¤¾à¤²à¥‡ à¤•à¤¾à¤°à¤£  (COST-AFFECTING PATTERNS)',
                  style: TextStyle(
                    fontSize: AppTheme.labelSize, fontWeight: FontWeight.w900,
                    color: Color(0xFFF59E0B), letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _patternRow('à¤«à¥à¤²à¥ˆà¤Ÿ à¤°à¥‡à¤Ÿ (Flat Rate) à¤•à¤¾ à¤à¤¾à¤‚à¤¸à¤¾  (Flat-rate presentation)'),
                _patternRow('à¤ªà¥ˆà¤¸à¥‡ à¤ªà¤¹à¤²à¥‡ à¤¹à¥€ à¤•à¤¾à¤Ÿ à¤²à¥‡à¤¨à¤¾  (Upfront deduction)'),
                _patternRow('à¤œà¤¬à¤°à¤¦à¤¸à¥à¤¤à¥€ à¤•à¤¾ à¤‡à¤‚à¤¶à¥à¤¯à¥‹à¤°à¥‡à¤‚à¤¸  (Insurance-related cost)'),
                const SizedBox(height: 8),
                const Text(
                  '3 cost-affecting patterns detected',
                  style: TextStyle(
                    fontSize: AppTheme.labelSize, fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // â”€â”€ Task 5-A: Evidence Trace Expander â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          GestureDetector(
            onTap: () => setState(() => _evidenceExpanded = !_evidenceExpanded),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: AppTheme.cardDecoration(borderColor: AppTheme.navy),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'à¤¹à¤®à¤¨à¥‡ à¤¯à¤¹ à¤•à¥ˆà¤¸à¥‡ à¤¹à¤¿à¤¸à¤¾à¤¬ à¤²à¤—à¤¾à¤¯à¤¾?\n(How did we calculate this?)',
                        style: TextStyle(
                          fontSize: AppTheme.bodyMin,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                        ),
                      ),
                      Icon(
                        _evidenceExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.navy, size: 28,
                      ),
                    ],
                  ),
                  if (_evidenceExpanded) ...[
                    const SizedBox(height: 16),
                    _evidenceRow('à¤²à¥‹à¤¨ à¤•à¥€ à¤°à¤•à¤®  (Sanctioned Amount)',
                        'â‚¹${terms.principal_amount.toStringAsFixed(0)}'),
                    _evidenceArrow(),
                    _evidenceRow('à¤ªà¥à¤°à¥‹à¤¸à¥‡à¤¸à¤¿à¤‚à¤— à¤«à¥€à¤¸  (Processing Fee)',
                        'â‚¹${terms.upfront_processing_fee.toStringAsFixed(0)}'),
                    _evidenceArrow(),
                    _evidenceRow('à¤‡à¤‚à¤¶à¥à¤¯à¥‹à¤°à¥‡à¤‚à¤¸ à¤•à¤¾ à¤–à¤°à¥à¤šà¤¾  (Insurance Cost)',
                        'â‚¹${(terms.monthly_insurance_premium * terms.tenure_months).toStringAsFixed(0)}'),
                    _evidenceArrow(),
                    _evidenceRow('à¤¹à¤¾à¤¥ à¤®à¥‡à¤‚ à¤•à¤¿à¤¤à¤¨à¥‡ à¤ªà¥ˆà¤¸à¥‡ à¤†à¤  (Net Amount Received)',
                        'â‚¹${calc.net_disbursed_amount.toStringAsFixed(0)}'),
                    _evidenceArrow(),
                    _evidenceRow('à¤¹à¤° à¤®à¤¹à¥€à¤¨à¥‡ à¤•à¥€ à¤•à¤¿à¤¶à¥à¤¤  (Monthly Cash Flow)',
                        'â‚¹${calc.actual_monthly_outflow.toStringAsFixed(0)}/month'),
                    _evidenceArrow(),
                    _evidenceRow('à¤®à¤¹à¥€à¤¨à¥‡ à¤•à¤¾ à¤¬à¥à¤¯à¤¾à¤œ à¤¦à¤°  (Monthly IRR)',
                        '${(calc.true_apr / 12).toStringAsFixed(2)}%'),
                    _evidenceArrow(),
                    _evidenceRow('à¤¸à¤¾à¤² à¤•à¤¾ à¤…à¤¸à¤²à¥€ à¤¬à¥à¤¯à¤¾à¤œ à¤¦à¤°  (Effective Annualized Cost)',
                        '${calc.true_apr.toStringAsFixed(2)}%',
                        highlight: true),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const RbiDraftScreen())),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy, foregroundColor: AppTheme.white),
            child: const Text('à¤…à¤ªà¤¨à¥€ à¤°à¤¿à¤ªà¥‹à¤°à¥à¤Ÿ à¤¦à¥‡à¤–à¥‡à¤‚  (Review Your Result)'),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Helper Widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _costChangeCard({required String title, required String subtitle, required String impact, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.red, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Text('âš ï¸ $impact', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {required bool dashed}) {
    return Row(
      children: [
        SizedBox(
          width: 32, height: 4,
          child: CustomPaint(painter: _LinePainter(color, dashed)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: AppTheme.labelSize,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }

  Widget _patternRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: AppTheme.bodyMin, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  Widget _evidenceRow(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.navy : AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? AppTheme.navy : AppTheme.border,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: AppTheme.labelSize,
                  color: highlight ? AppTheme.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                )),
          ),
          Text(value,
              style: TextStyle(
                fontSize: AppTheme.bodyMin,
                fontWeight: AppTheme.numberWeight,
                color: highlight ? AppTheme.white : AppTheme.navy,
                letterSpacing: -0.5,
              )),
        ],
      ),
    );
  }

  Widget _evidenceArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: Icon(Icons.arrow_downward_rounded, color: AppTheme.textSecondary, size: 18),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool dashed;
  _LinePainter(this.color, this.dashed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    if (!dashed) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    } else {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset((x + 6).clamp(0, size.width), size.height / 2),
          paint,
        );
        x += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

