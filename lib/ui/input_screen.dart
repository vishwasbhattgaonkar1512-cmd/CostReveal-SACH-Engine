import 'package:flutter/material.dart';
import 'validation_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> with SingleTickerProviderStateMixin {
  bool _isDemoMode = false;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoanKaSach'),
        actions: [
          Row(
            children: [
              const Text('Demo Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: _isDemoMode,
                activeThumbColor: Colors.amber, // Distinct amber color
                onChanged: (val) {
                  setState(() {
                    _isDemoMode = val;
                  });
                },
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
              const Text(
                'Loan ki sacchai jaaniye.',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              // Massive Pulsing Microphone Button
              Center(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Gemini Voice/Vision Routing
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A), // Navy
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(Icons.mic, color: Colors.white, size: 72),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bol kar batayein',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              
              const Spacer(),
              
              const Text(
                'Ya khud select karein:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              
              // Demoted Quick-Tap Chips (Secondary Row)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSmallChip('Upfront Deduction ✂️'),
                    const SizedBox(width: 12),
                    _buildSmallChip('Ghost Insurance 👻'),
                    const SizedBox(width: 12),
                    _buildSmallChip('Flat Rate 📉'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ValidationScreen()),
                  );
                },
                child: const Text('Start Manual Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallChip(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        borderRadius: BorderRadius.circular(24), // Pill shape for secondary chips
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
