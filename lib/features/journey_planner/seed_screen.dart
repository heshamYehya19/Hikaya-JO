import 'package:flutter/material.dart';
import '../../core/services/seed_service.dart';
import '../../core/theme/colors.dart';

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  bool _isSeeding = false;
  String _status = 'Not seeded yet';

  Future<void> _runSeed() async {
    setState(() {
      _isSeeding = true;
      _status = 'Seeding...';
    });
    try {
      await SeedService().seedDestinations();
      setState(() => _status = '✅ 10 destinations seeded successfully');
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Destinations (Dev Only)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSeeding ? null : _runSeed,
                child: _isSeeding
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Seed Firestore Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}