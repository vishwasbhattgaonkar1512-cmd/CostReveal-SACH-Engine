import 'package:flutter/material.dart';
import 'validation_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({Key? key}) : super(key: key);

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  bool _isDemoMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Loan Details'),
        actions: [
          Row(
            children: [
              const Text('Demo Mode'),
              Switch(
                value: _isDemoMode,
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ValidationScreen()),
                );
              },
              child: const Text('Manual Entry'),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Voice Entry (Coming Soon)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Camera Entry (Coming Soon)'),
            ),
          ],
        ),
      ),
    );
  }
}
