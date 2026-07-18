import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/localization/app_locale.dart';
import '../../providers/journey_provider.dart';
import 'itinerary_screen.dart';

class JourneyPlannerInputScreen extends ConsumerStatefulWidget {
  const JourneyPlannerInputScreen({super.key});

  @override
  ConsumerState<JourneyPlannerInputScreen> createState() => _JourneyPlannerInputScreenState();
}

class _JourneyPlannerInputScreenState extends ConsumerState<JourneyPlannerInputScreen> {
  final List<String> _interestKeys = ['history', 'nature', 'adventure', 'culture', 'food', 'relaxation'];
  final Set<String> _selectedInterests = {};
  String _budget = 'medium';
  String _transport = 'car';
  double _hours = 6;
  bool _isGenerating = false;

  IconData _iconForInterest(String key) {
    switch (key) {
      case 'history':
        return Icons.account_balance_outlined;
      case 'nature':
        return Icons.terrain_outlined;
      case 'adventure':
        return Icons.hiking_outlined;
      case 'culture':
        return Icons.temple_buddhist_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'relaxation':
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
    final t = AppLocale.of(context).t;

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('plan_pick_interest_error'))),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final destinations = await ref.read(allDestinationsProvider.future);
      final interestsForPrompt = _selectedInterests.map((key) => AppLocale.of(context).t('interest_$key')).toList();

      final journey = await ref.read(journeyServiceProvider).generateJourney(
        destinations: destinations,
        interests: interestsForPrompt,
        budgetLevel: _budget,
        availableHours: _hours.round(),
        transportMode: _transport,
      );
      ref.read(currentJourneyProvider.notifier).state = journey;

      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ItineraryScreen()));
      }

      ref.read(journeyServiceProvider).saveJourney(journey).catchError((e) {
        debugPrint('Failed to save journey: $e');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t('plan_generate_error')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.of(context).t;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(t('plan_title'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('plan_subtitle'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              Text(t('plan_interests_heading'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: _interestKeys.map((key) {
                  final selected = _selectedInterests.contains(key);
                  return _SelectableTile(
                    icon: _iconForInterest(key),
                    label: t('interest_$key'),
                    selected: selected,
                    onTap: () => setState(() {
                      selected ? _selectedInterests.remove(key) : _selectedInterests.add(key);
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text(t('plan_budget_heading'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
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
              Text(t('plan_transport_heading'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Row(
                children: ['walking', 'car', 'public'].map((mode) {
                  final selected = _transport == mode;
                  final label = mode == 'car' ? t('transport_car') : (mode == 'public' ? t('transport_bus') : t('transport_walking'));
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: mode != 'public' ? 10 : 0),
                      child: _SelectableTile(
                        icon: _iconForTransport(mode),
                        label: label,
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
                  Text(t('plan_hours_heading'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.deepTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_hours.round()} ${t('unit_hours')}',
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
                      : Text(t('plan_generate_button')),
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
  const _SelectableTile({required this.icon, required this.label, required this.selected, required this.onTap});

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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? AppColors.deepTeal : AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}