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
          final appState = Provider.of<AppProvider>(context, listen: false);
          if ((appState.calculationResult?.total_hidden_cost ?? 0) > 0) {
            HapticFeedback.heavyImpact();
            setState(() => _showRed = true);
            _redCtrl.forward();
          }
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
      return const Scaffold(body: Center(child: Text('कोई डेटा नहीं।')));
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
    final patternCount = [true, terms.upfront_processing_fee > 0, terms.monthly_insurance_premium > 0].where((e) => e).length;

    // Severity scale — purely UI, no backend changes
    // Compare True APR vs what the lender *advertised*
    final double ratio = terms.advertised_flat_rate > 0
        ? calc.true_apr / terms.advertised_flat_rate
        : double.infinity;

    // 3-tier severity
    final bool isLow    = ratio < 1.5;   // < 1.5× → slightly above fair
    final bool isMedium = ratio >= 1.5 && ratio < 2.0; // 1.5–2× → expensive
    // isMedium == false && isLow == false → > 2× → predatory

    final Color severityColor = isLow
        ? const Color(0xFFD97706)   // amber/yellow
        : isMedium
            ? const Color(0xFFEA580C)  // orange
            : AppTheme.red;            // red

    final String severityLabel = isLow
        ? 'थोड़ा महंगा'
        : isMedium
            ? 'महंगा लोन'
            : 'बहुत महंगा';

    final String severityLabelEn = isLow
        ? 'Slightly Above Fair'
        : isMedium
            ? 'Expensive Loan'
            : 'High Effective Cost';

    final String severitySubtext = isLow
        ? 'यह लोन थोड़ा महंगा है, लेकिन स्वीकार्य है।'
        : isMedium
            ? 'यह लोन ज़रूरत से ज़्यादा महंगा है।'
            : 'Additional borrowing cost detected.';

    final IconData severityIcon = isLow
        ? Icons.info_rounded
        : isMedium
            ? Icons.warning_rounded
            : Icons.dangerous_rounded;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('असली सच (True Cost)')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        children: [
          // Hero APR Card — severity-aware
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppTheme.cardPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [severityColor, severityColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: severityColor.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                // Severity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(severityIcon, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '$severityLabel  •  $severityLabelEn',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // True APR number
                Text(
                  '${calc.true_apr.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: AppTheme.numberWeight,
                    color: AppTheme.white,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'असली ब्याज दर (True APR)',
                  style: TextStyle(fontSize: AppTheme.labelSize, color: Colors.white70, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Ratio pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'बताई गई दर ${terms.advertised_flat_rate.toStringAsFixed(1)}% → असली ${calc.true_apr.toStringAsFixed(1)}%  (${ratio.toStringAsFixed(1)}× ज़्यादा)',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  severitySubtext,
                  style: const TextStyle(fontSize: AppTheme.labelSize, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Chart Section
          Container(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              children: [
                const Text(
                  'आपको कुल कितना देना होगा?',
                  style: TextStyle(fontSize: AppTheme.bodyMin, fontWeight: FontWeight.bold, color: AppTheme.navy),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.border.withValues(alpha: 0.5), strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: vGreen, isCurved: true, curveSmoothness: 0.1,
                            color: AppTheme.green, barWidth: 4,
                            dotData: FlDotData(show: false), dashArray: null,
                          ),
                          if (vRed.isNotEmpty)
                            LineChartBarData(
                              spots: vRed, isCurved: true, curveSmoothness: 0.1,
                              color: severityColor, barWidth: 4,
                              dotData: FlDotData(show: false), dashArray: [8, 4],
                            ),
                        ],
                        betweenBarsData: vRed.isNotEmpty
                            ? [BetweenBarsData(
                                fromIndex: 0, toIndex: 1,
                                color: severityColor.withValues(alpha: 0.12),
                              )]
                            : [],
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Chart legend — always shown, uses severityColor for the "true" line
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            children: [
              _legendItem(AppTheme.green, 'जो बताया गया (Promised)', dashed: false),
              _legendItem(severityColor, 'असली सच (True Cost)', dashed: true),
            ],
          ),

          const SizedBox(height: 24),

          // Hidden Cost card — severity-aware colours
          Container(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: severityColor.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(severityIcon, color: severityColor, size: 28),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '₹${calc.total_hidden_cost.toStringAsFixed(0)} अतिरिक्त लागत (Extra Cost)',
                        style: TextStyle(
                          fontSize: 32, fontWeight: AppTheme.numberWeight,
                          color: severityColor, letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Extra cost vs fair reducing-balance loan',
                  style: TextStyle(fontSize: AppTheme.labelSize, color: severityColor, fontWeight: FontWeight.w500),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.black12, height: 1),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(Icons.school_rounded, color: AppTheme.navy, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'मतलब ${schoolMonths.toStringAsFixed(1)} महीने की स्कूल फीस!',
                            style: const TextStyle(fontSize: AppTheme.bodyMin, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '= ${schoolMonths.toStringAsFixed(1)} months of school fees (NSSO benchmark)',
                            style: const TextStyle(fontSize: AppTheme.labelSize, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'महंगा क्यों हुआ? (What Changed the Cost?)',
            style: TextStyle(fontSize: AppTheme.bodyMin, fontWeight: FontWeight.w700, color: AppTheme.navy),
          ),
          const SizedBox(height: 12),

          _costChangeCard(
            title: 'फ्लैट रेट (Flat Rate)',
            subtitle: 'ब्याज पूरी मूल राशि पर लगा है, घटते हुए बैलेंस पर नहीं। यही सबसे बड़ा कारण है।',
            impact: 'असली APR लगभग 2× हो जाती है',
            icon: Icons.percent_rounded,
          ),
          if (terms.upfront_processing_fee > 0)
            _costChangeCard(
              title: 'प्रोसेसिंग फीस (Processing Fee)',
              subtitle: '₹${terms.upfront_processing_fee.toStringAsFixed(0)} पहले ही काट लिए गए, लेकिन ब्याज पूरी रकम पर लगता है।',
              impact: '₹${terms.upfront_processing_fee.toStringAsFixed(0)} कम हाथ में आया',
              icon: Icons.money_off_rounded,
            ),
          if (terms.monthly_insurance_premium > 0)
            _costChangeCard(
              title: 'बीमा (Insurance)',
              subtitle: 'हर महीने ₹${terms.monthly_insurance_premium.toStringAsFixed(0)} का बीमा किश्त में जुड़ा है।',
              impact: 'कुल ₹${(terms.monthly_insurance_premium * terms.tenure_months).toStringAsFixed(0)} बीमे में गए',
              icon: Icons.health_and_safety_rounded,
            ),

          const SizedBox(height: 16),

          // Patterns summary card — severity-aware border
          Container(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: severityColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(severityIcon, color: severityColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'लोन को महंगा बनाने वाले कारण (Cost-Affecting Patterns)',
                        style: TextStyle(
                          fontSize: AppTheme.labelSize, fontWeight: FontWeight.w900,
                          color: severityColor, letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _patternRow('फ्लैट रेट (Flat Rate) का झांसा'),
                if (terms.upfront_processing_fee > 0) _patternRow('पैसे पहले ही काट लेना (Upfront deduction)'),
                if (terms.monthly_insurance_premium > 0) _patternRow('ज़बरदस्ती का इंश्योरेंस (Forced Insurance)'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.black12, height: 1),
                ),
                Text(
                  '$patternCount कारण मिले ($patternCount patterns detected)',
                  style: const TextStyle(
                    fontSize: AppTheme.labelSize, fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Evidence Trace (Receipt Style)
          GestureDetector(
            onTap: () => setState(() => _evidenceExpanded = !_evidenceExpanded),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.border, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'हमने यह कैसे हिसाब लगाया?\n(How did we calculate this?)',
                          style: TextStyle(
                            fontSize: AppTheme.bodyMin,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy,
                          ),
                        ),
                      ),
                      Icon(
                        _evidenceExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.navy, size: 28,
                      ),
                    ],
                  ),
                  if (_evidenceExpanded) ...[
                    const SizedBox(height: 16),
                    _evidenceRow('लोन की रकम\n(Sanctioned Amount)', '₹${calc.sanctioned_amount.toStringAsFixed(0)}'),
                    _evidenceArrow(),
                    _evidenceRow('प्रोसेसिंग फीस\n(Processing Fee)', '- ₹${calc.processing_fee.toStringAsFixed(0)}', isDeduction: true),
                    _evidenceArrow(),
                    _evidenceRow('इंश्योरेंस का खर्चा\n(Insurance Cost)', '- ₹${calc.insurance_cost.toStringAsFixed(0)}', isDeduction: true),
                    _evidenceArrow(),
                    _evidenceRow('आपको वास्तव में मिले\n(Net Received)', '₹${calc.net_disbursed_amount.toStringAsFixed(0)}', isBold: true, isGreen: true),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.black12, height: 1),
                    ),
                    _evidenceRow('हर महीने की किश्त\n(Monthly Cash Flow)', '₹${calc.actual_monthly_outflow.toStringAsFixed(0)}/mo', isBold: true),
                    _evidenceRow('महीने का ब्याज दर\n(Monthly IRR)', '${calc.monthly_irr.toStringAsFixed(2)}%'),
                    const SizedBox(height: 12),
                    _evidenceRow('असली ब्याज दर\n(True APR)', '${calc.true_apr.toStringAsFixed(2)}%', highlight: true),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const RbiDraftScreen())),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy, foregroundColor: AppTheme.white,
                elevation: 4,
                shadowColor: AppTheme.navy.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 60)),
            child: const Text(
              'अपनी रिपोर्ट देखें (Review Your Result)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _costChangeCard({required String title, required String subtitle, required String impact, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('⚠️ $impact', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {required bool dashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32, height: 4,
          child: CustomPaint(painter: _LinePainter(color, dashed)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label,
              style: TextStyle(
                  fontSize: AppTheme.labelSize,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      ],
    );
  }

  Widget _patternRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.circle, color: Color(0xFFF59E0B), size: 8),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: AppTheme.bodyMin, color: AppTheme.textPrimary, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _evidenceRow(String label, String value, {bool highlight = false, bool isDeduction = false, bool isBold = false, bool isGreen = false}) {
    if (highlight) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.navy, Color(0xFF1E40AF)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: AppTheme.labelSize, color: AppTheme.white, fontWeight: FontWeight.w600)),
            ),
            Text(value,
                style: const TextStyle(fontSize: 20, fontWeight: AppTheme.numberWeight, color: AppTheme.white)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontSize: AppTheme.labelSize,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                )),
          ),
          const SizedBox(width: 16),
          Text(value,
              style: TextStyle(
                fontSize: AppTheme.bodyMin,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isGreen ? AppTheme.green : (isDeduction ? AppTheme.red : AppTheme.navy),
                letterSpacing: -0.5,
              )),
        ],
      ),
    );
  }

  Widget _evidenceArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 24),
      child: Icon(Icons.arrow_downward_rounded, color: Colors.black26, size: 18),
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
