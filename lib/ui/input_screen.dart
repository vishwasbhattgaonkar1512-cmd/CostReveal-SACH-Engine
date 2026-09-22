import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bridge/sensor_handler.dart';
import '../bridge/gemini_api.dart';
import '../state/app_state.dart';
import 'validation_screen.dart';
import 'fallback_screen.dart';
import 'widgets/bouncing_touch.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen>
    with SingleTickerProviderStateMixin {
  bool _isDemoMode = false;
  bool _isListening = false;
  bool _isCapturing = false;
  bool _isAiProcessing = false;

  final SensorHandler _sensor = SensorHandler();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sensor.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // VOICE ENTRY
  // ─────────────────────────────────────────────────────────────

  Future<void> _onMicTap() async {
    if (_isListening || _isAiProcessing) return;

    setState(() {
      _isListening = true;
    });

    _pulseController.stop();

    try {
      final String spokenText = await _sensor.listenForSpeech();

      if (!mounted) return;

      if (spokenText.trim().isEmpty) {
        _showSnack('कोई आवाज़ नहीं आई। दोबारा कोशिश करें।');
        return;
      }

      _showSpeechConfirmDialog(spokenText);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      _goToFallback();
    } finally {
      if (mounted) {
        setState(() {
          _isListening = false;
        });

        _pulseController.repeat(reverse: true);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SPEECH CONFIRMATION
  // ─────────────────────────────────────────────────────────────

  void _showSpeechConfirmDialog(String spokenText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'आपने कहा:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
              ),
              child: Text(
                '"$spokenText"',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'आपकी लोन जानकारी तैयार की जा रही है…\n'
              'कृपया नीचे विवरण जाँचें।',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('वापस जाएं'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_isAiProcessing) return;

              setState(() {
                _isAiProcessing = true;
              });

              Navigator.pop(ctx);

              setState(() {
                _isListening = true;
              });

              try {
                _showSnack('आवाज़ मिली! AI से जानकारी निकाल रहे हैं…');

                final geminiApi = GeminiApi();

                final candidateTerms = await geminiApi.extractFromText(
                  spokenText,
                );

                if (!mounted) return;

                Provider.of<AppProvider>(
                  context,
                  listen: false,
                ).setCandidateTerms(candidateTerms);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ValidationScreen()),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).clearSnackBars();
                _goToFallback();
              } finally {
                if (mounted) {
                  setState(() {
                    _isListening = false;
                    _isAiProcessing = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('विवरण जाँचें'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CAMERA ENTRY
  // ─────────────────────────────────────────────────────────────

  Future<void> _onCameraTap() async {
    if (_isCapturing || _isAiProcessing) return;

    setState(() {
      _isCapturing = true;
      _isAiProcessing = true;
    });

    try {
      await _sensor.initializeCamera();

      final String base64Image = await _sensor.captureImageAsBase64();

      if (!mounted) return;

      final appProvider = Provider.of<AppProvider>(context, listen: false);

      appProvider.setPendingCameraImage(base64Image);

      _showSnack('फोटो मिली! AI से जानकारी निकाल रहे हैं…');

      final geminiApi = GeminiApi();

      final candidateTerms = await geminiApi.extractFromImage(base64Image);

      if (!mounted) return;

      appProvider.setCandidateTerms(candidateTerms);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ValidationScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      _goToFallback();
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isAiProcessing = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FALLBACK
  // ─────────────────────────────────────────────────────────────

  void _goToFallback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FallbackScreen()),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SNACKBAR
  // ─────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B35),

      // ─────────────────────────────────────────────────────────
      // APP BAR
      // ─────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'CostReveal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        actions: [
          Row(
            children: [
              Text(
                'डेमो मोड',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),

              Switch(
                value: _isDemoMode,
                activeThumbColor: Colors.amber,
                activeTrackColor: Colors.amber.withValues(alpha: 0.4),
                onChanged: (val) {
                  setState(() {
                    _isDemoMode = val;
                  });
                },
              ),
            ],
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ─────────────────────────────────────────────────────────
      // BODY
      // ─────────────────────────────────────────────────────────
      body: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // RESPONSIVE HERO SECTION
            // =====================================================
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double height = constraints.maxHeight;

                  // Short devices / keyboard / small viewport
                  final bool compact = height < 400;

                  final double micSize = compact ? 95 : 120;

                  final double outerSize1 = compact ? 125 : 160;

                  final double outerSize2 = compact ? 110 : 140;

                  final double headlineSize = compact ? 29 : 36;

                  final double topSpacing = compact ? 8 : 28;

                  final double headlineSpacing = compact ? 8 : 12;

                  final double micSpacing = compact ? 18 : 48;

                  final double textSpacing = compact ? 10 : 20;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        // ─────────────────────────────
                        // OFFLINE BADGE
                        // ─────────────────────────────
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: compact ? 5 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                color: Color(0xFF10B981),
                                size: 8,
                              ),

                              SizedBox(width: 6),

                              Text(
                                'OFFLINE • सुरक्षित',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: topSpacing),

                        // ─────────────────────────────
                        // HEADLINE
                        // ─────────────────────────────
                        Text(
                          'लोन का असली सच\nजानें।',
                          style: TextStyle(
                            fontSize: headlineSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: headlineSpacing),

                        // ─────────────────────────────
                        // SUBTITLE
                        // ─────────────────────────────
                        Text(
                          'बैंक जो नहीं बताता, हम बताते हैं।\n'
                          '(We reveal what the bank hides.)',
                          style: TextStyle(
                            fontSize: compact ? 13 : 15,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: micSpacing),

                        // ─────────────────────────────
                        // MICROPHONE
                        // ─────────────────────────────
                        GestureDetector(
                          onTap: _onMicTap,

                          child: AnimatedBuilder(
                            animation: _pulseAnimation,

                            builder: (context, child) {
                              return SizedBox(
                                width: outerSize1,
                                height: outerSize1,

                                child: Stack(
                                  alignment: Alignment.center,

                                  children: [
                                    // Outer pulse
                                    if (!_isListening)
                                      Transform.scale(
                                        scale: _pulseAnimation.value,

                                        child: Container(
                                          width: outerSize1,
                                          height: outerSize1,

                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Inner pulse
                                    if (!_isListening)
                                      Transform.scale(
                                        scale: (_pulseAnimation.value + 1) / 2,

                                        child: Container(
                                          width: outerSize2,
                                          height: outerSize2,

                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Main microphone
                                    Container(
                                      height: micSize,
                                      width: micSize,

                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _isListening
                                              ? const [
                                                  Color(0xFFDC2626),
                                                  Color(0xFFB91C1C),
                                                ]
                                              : const [
                                                  Color(0xFF3B82F6),
                                                  Color(0xFF1E3A8A),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),

                                        shape: BoxShape.circle,

                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (_isListening
                                                        ? const Color(
                                                            0xFFDC2626,
                                                          )
                                                        : const Color(
                                                            0xFF3B82F6,
                                                          ))
                                                    .withValues(alpha: 0.5),
                                            blurRadius: compact ? 20 : 30,
                                            spreadRadius: compact ? 2 : 4,
                                          ),
                                        ],
                                      ),

                                      child: Icon(
                                        _isListening
                                            ? Icons.mic_none_rounded
                                            : Icons.mic_rounded,
                                        color: Colors.white,
                                        size: compact ? 44 : 56,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: textSpacing),

                        // ─────────────────────────────
                        // MIC STATUS
                        // ─────────────────────────────
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),

                          child: Text(
                            _isListening
                                ? 'सुन रहा हूँ… (Listening…)'
                                : _isAiProcessing
                                ? 'AI जानकारी निकाल रहा है…'
                                : 'यहाँ दबाएं और बोलें',

                            key: ValueKey(_isListening || _isAiProcessing),

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: compact ? 14 : 16,

                              color: _isListening
                                  ? const Color(0xFFDC2626)
                                  : Colors.white.withValues(alpha: 0.6),

                              fontWeight: _isListening
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ));
                },
              ),
            ),

            // =====================================================
            // BOTTOM ACTION CARD
            // =====================================================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),

              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),

                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                mainAxisSize: MainAxisSize.min,

                children: [
                  // ─────────────────────────────
                  // HANDLE
                  // ─────────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,

                      margin: const EdgeInsets.only(bottom: 14),

                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ─────────────────────────────
                  // TITLE
                  // ─────────────────────────────
                  const Text(
                    'या दूसरे तरीके से जानकारी दें',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ─────────────────────────────
                  // ACTION TILES
                  // ─────────────────────────────
                  Row(
                    children: [
                      // CAMERA
                      Expanded(
                        child: _buildActionTile(
                          icon: _isCapturing
                              ? Icons.hourglass_top_rounded
                              : Icons.camera_alt_rounded,

                          label: _isCapturing
                              ? 'स्कैन हो रहा है…'
                              : 'KFS फोटो लें',

                          sublabel: 'Camera scan',

                          color: const Color(0xFF7C3AED),

                          onTap: _onCameraTap,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // MANUAL ENTRY
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.edit_rounded,

                          label: 'खुद टाइप करें',

                          sublabel: 'Manual entry',

                          color: const Color(0xFF0284C7),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ValidationScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ─────────────────────────────
                  // GET STARTED BUTTON
                  // ─────────────────────────────
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ValidationScreen(),
                        ),
                      );
                    },

                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),

                    label: const Text(
                      'लोन का सच जानें (Get Started)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),

                      foregroundColor: Colors.white,

                      minimumSize: const Size(double.infinity, 56),

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'How CostReveal Works',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _trustStep(Icons.auto_awesome, 'AI\nExtracts'),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.black26),
                              ),
                              _trustStep(Icons.person_rounded, 'HUMAN\nVerifies'),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.black26),
                              ),
                              _trustStep(Icons.calculate_rounded, 'ENGINE\nCalculates'),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.black26),
                              ),
                              _trustStep(Icons.analytics_rounded, 'EVIDENCE\nExplains'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ACTION TILE
  // ─────────────────────────────────────────────────────────────

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),

                borderRadius: BorderRadius.circular(10),
              ),

              child: Icon(icon, color: color, size: 22),
            ),

            const SizedBox(height: 10),

            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              sublabel,
              style: const TextStyle(fontSize: 12, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trustStep(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
        ),
      ],
    );
  }
}
