import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../providers/journey_provider.dart';
import 'itinerary_screen.dart';

class JourneyPlannerInputScreen extends ConsumerStatefulWidget {
  const JourneyPlannerInputScreen({super.key});

  @override
  ConsumerState<JourneyPlannerInputScreen> createState() => _JourneyPlannerInputScreenState();
}

class _JourneyPlannerInputScreenState extends ConsumerState<JourneyPlannerInputScreen> {
  final List<String> _allInterests = ['History', 'Nature', 'Adventure', 'Culture', 'Food', 'Relaxation'];
  final Set<String> _selectedInterests = {};
  String _budget = 'medium';
  String _transport = 'car';
  double _hours = 6;
  bool _isGenerating = false;

  Future<void> _generate() async {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one interest')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final journey = await ref.read(journeyServiceProvider).generateJourney(
        interests: _selectedInterests.toList(),
        budgetLevel: _budget,
        availableHours: _hours.round(),
        transportMode: _transport,
      );
      ref.read(currentJourneyProvider.notifier).state = journey;
      await ref.read(journeyServiceProvider).saveJourney(journey); // persist it
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ItineraryScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate journey: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Plan Your Journey')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What are you interested in?', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allInterests.map((interest) {
                  final selected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: selected,
                    onSelected: (val) => setState(() {
                      val ? _selectedInterests.add(interest) : _selectedInterests.remove(interest);
                    }),
                    selectedColor: AppColors.deepTeal.withOpacity(0.15),
                    checkmarkColor: AppColors.deepTeal,
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text('Budget level', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'low', label: Text('Low')),
                  ButtonSegment(value: 'medium', label: Text('Medium')),
                  ButtonSegment(value: 'high', label: Text('High')),
                ],
                selected: {_budget},
                onSelectionChanged: (val) => setState(() => _budget = val.first),
              ),
              const SizedBox(height: 28),
              Text('Transport mode', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'car', label: Text('Car')),
                  ButtonSegment(value: 'public', label: Text('Public')),
                  ButtonSegment(value: 'walking', label: Text('Walking')),
                ],
                selected: {_transport},
                onSelectionChanged: (val) => setState(() => _transport = val.first),
              ),
              const SizedBox(height: 28),
              Text('Available time: ${_hours.round()} hours', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              Slider(
                value: _hours,
                min: 2,
                max: 12,
                divisions: 10,
                activeColor: AppColors.deepTeal,
                onChanged: (val) => setState(() => _hours = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generate,
                  child: _isGenerating
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Generate My Journey'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}