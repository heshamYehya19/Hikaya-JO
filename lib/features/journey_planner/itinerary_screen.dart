import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../providers/journey_provider.dart';

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(currentJourneyProvider);

    if (journey == null) {
      return const Scaffold(body: Center(child: Text('No journey generated yet')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Your Journey')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.deepTeal.withOpacity(0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(label: 'Stops', value: '${journey.stops.length}'),
                  _StatChip(label: 'Duration', value: '${(journey.totalDurationMinutes / 60).toStringAsFixed(1)}h'),
                  _StatChip(label: 'Est. Cost', value: '${journey.totalCost.toStringAsFixed(0)} JOD'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: journey.stops.length,
                itemBuilder: (context, index) {
                  final stop = journey.stops[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.duneLight),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.deepTeal,
                                child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stop.destinationName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('${stop.suggestedTime} · ${stop.durationMinutes} min · ${stop.estimatedCost.toStringAsFixed(0)} JOD',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text(stop.notes, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.deepTeal)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}