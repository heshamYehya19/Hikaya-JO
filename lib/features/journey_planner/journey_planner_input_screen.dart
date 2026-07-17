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

  IconData _iconForInterest(String interest) {
    switch (interest) {
      case 'History':
        return Icons.account_balance_outlined;
      case 'Nature':
        return Icons.terrain_outlined;
      case 'Adventure':
        return Icons.hiking_outlined;
      case 'Culture':
        return Icons.temple_buddhist_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Relaxation':
        return Icons.spa_outlined;
      default:
        return Icons.explore_outlined;
    }
  }

  IconData _iconForTransport(String mode) {
    switch (mode) {
      case 'car':
        return Icons.directions_car_outlined;
      case 'public':
        return Icons.directions_bus_outlined;
      case 'walking':
        return Icons.directions_walk_outlined;
      default:
        return Icons.commute_outlined;
    }
  }

  String _labelForTransport(String mode) {
    switch (mode) {
      case 'car':
        return 'Car';
      case 'public':
        return 'Bus';
      case 'walking':
        return 'Walking';
      default:
        return mode;
    }
  }

  String _symbolForBudget(String level) {
    switch (level) {
      case 'low':
        return '\$';
      case 'medium':
        return '\$\$';
      case 'high':
        return '\$\$\$';
      default:
        return '';
    }
  }

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
              const Text('Craft your perfect adventure',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              Text('What are you interested in?', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: _allInterests.map((interest) {
                  final selected = _selectedInterests.contains(interest);
                  return _SelectableTile(
                    icon: _iconForInterest(interest),
                    label: interest,
                    selected: selected,
                    onTap: () => setState(() {
                      selected ? _selectedInterests.remove(interest) : _selectedInterests.add(interest);
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text('Budget', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Row(
                children: ['low', 'medium', 'high'].map((level) {
                  final selected = _budget == level;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: level != 'high' ? 10 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _budget = level),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.deepTeal.withOpacity(0.15) : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: selected ? AppColors.deepTeal : AppColors.duneLight),
                          ),
                          child: Center(
                            child: Text(
                              _symbolForBudget(level),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: selected ? AppColors.deepTeal : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text('Transport', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Row(
                children: ['walking', 'car', 'public'].map((mode) {
                  final selected = _transport == mode;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: mode != 'public' ? 10 : 0),
                      child: _SelectableTile(
                        icon: _iconForTransport(mode),
                        label: _labelForTransport(mode),
                        selected: selected,
                        onTap: () => setState(() => _transport = mode),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('How many hours?', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.deepTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_hours.round()} Hours',
                        style: const TextStyle(color: AppColors.deepTeal, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
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
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
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

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepTeal.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.deepTeal : AppColors.duneLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppColors.deepTeal : AppColors.textSecondary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.deepTeal : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
