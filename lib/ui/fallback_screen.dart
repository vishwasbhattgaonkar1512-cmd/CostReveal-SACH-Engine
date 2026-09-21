import 'package:flutter/material.dart';
import 'validation_screen.dart';

/// Screen 5: Global Fallback / Offline Resilience
/// Triggered by AIUnavailableException, HTTP 429, or no WiFi.
/// Silently logs failure count and auto-routes to manual mode.
class FallbackScreen extends StatefulWidget {
  const FallbackScreen({super.key});

  @override
  State<FallbackScreen> createState() => _FallbackScreenState();
}

class _FallbackScreenState extends State<FallbackScreen> {
  // Silent failure counter (in-memory, can wire to SharedPreferences later)
  static int _failureCount = 0;

  @override
  void initState() {
    super.initState();
    _failureCount++;

    // Auto-route back to manual mode after 3 seconds — zero panic
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ValidationScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 80,
                color: Color(0xFF1E3A8A),
              ),
              const SizedBox(height: 32),
              const Text(
                'AI Network Unavailable.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Routing to Secure Manual.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const LinearProgressIndicator(
                color: Color(0xFF1E3A8A),
                backgroundColor: Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 8),
              const Text(
                'Redirecting to manual entry...',
                style: TextStyle(fontSize: 13, color: Colors.black45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              // Debug info for judges — silent counter surfaced on this screen only
              Text(
                'Recovered $_failureCount time${_failureCount == 1 ? '' : 's'} this session.',
                style: const TextStyle(fontSize: 12, color: Colors.black26),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
