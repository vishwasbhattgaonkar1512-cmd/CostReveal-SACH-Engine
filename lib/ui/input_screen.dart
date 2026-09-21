import 'package:flutter/material.dart';
import '../bridge/sensor_handler.dart';
import '../bridge/gemini_api.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';
import 'validation_screen.dart';
import 'fallback_screen.dart';
import 'widgets/bouncing_touch.dart'; // <--- PREMIUM ADDITION

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

  // ── Voice Entry ─────────────────────────────────────────────────────────
  Future<void> _onMicTap() async {
    if (_isListening || _isAiProcessing) return;

    setState(() => _isListening = true);
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
        setState(() => _isListening = false);
        _pulseController.repeat(reverse: true);
      }
    }
  }

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
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'आपकी लोन जानकारी तैयार की जा रही है…\nकृपया नीचे विवरण जाँचें।',
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
              setState(() => _isAiProcessing = true);
              
              Navigator.pop(ctx);
              
              setState(() => _isListening = true);
              try {
                _showSnack('आवाज़ मिली! AI से जानकारी निकाल रहे हैं…');
                final geminiApi = GeminiApi();
                final candidateTerms = await geminiApi.extractFromText(spokenText);
                
                if (!mounted) return;
                Provider.of<AppProvider>(context, listen: false)
                    .setCandidateTerms(candidateTerms);
                    
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
            ),
            child: const Text('विवरण जाँचें'),
          ),
        ],
      ),
    );
  }

  // ── Camera Entry ─────────────────────────────────────────────────────────
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

  void _goToFallback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FallbackScreen()),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pie_chart_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('CostReveal'),
          ],
        ),
        actions: [
          Row(
            children: [
              const Text('डेमो मोड',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Switch(
                value: _isDemoMode,
                activeThumbColor: Colors.amber,
                activeTrackColor: Colors.amber.withValues(alpha: 0.4),
                onChanged: (val) => setState(() => _isDemoMode = val),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
                      SizedBox(width: 6),
                      Text(
                        '🟢 OFFLINE MODE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'लोन का असली सच जानें।',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── HERO: Pulsing/Listening Mic ────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _onMicTap,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? 1.0 : _pulseAnimation.value,
                        child: Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? const Color(0xFFDC2626) // Red = recording
                                : const Color(0xFF1E3A8A), // Navy = ready
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF1E3A8A))
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_none : Icons.mic,
                            color: Colors.white,
                            size: 72,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                _isListening
                    ? 'सुन रहा हूँ… (Listening…)'
                    : 'बोल कर बताएं',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: _isListening
                      ? const Color(0xFFDC2626)
                      : Colors.black54,
                  fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
                ),
              ),

              const Spacer(),

              const Text(
                'या खुद भरें:',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
              const SizedBox(height: 12),

              // ── Secondary: Camera + Manual chips ─────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip(
                      icon: _isCapturing
                          ? Icons.hourglass_top_rounded
                          : Icons.camera_alt_rounded,
                      label: _isCapturing ? 'फोटो स्कैन हो रही है…' : 'KFS की फोटो लें',
                      onTap: _onCameraTap,
                    ),
                    const SizedBox(width: 12),
                    _buildChip(
                      icon: Icons.edit_rounded,
                      label: 'खुद टाइप करें',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ValidationScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ValidationScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text(
                  'खुद टाइप करें  (Manual Entry)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return BouncingTouch(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

