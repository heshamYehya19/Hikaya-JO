import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/journey_service.dart';
import '../../core/services/story_guide_service.dart';
import '../../core/theme/colors.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';
import '../../providers/journey_provider.dart';
import 'destination_detail_screen.dart';
import 'journey_map_screen.dart';
import '../../core/services/offline_service.dart';

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => JourneyMapScreen(journey: journey)),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('View on Map'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadForOffline(context, ref, journey),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download for Offline'),
                ),
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
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DestinationDetailScreen(destinationId: stop.destinationId)),
                        ),
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
                      ) );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _downloadForOffline(BuildContext context, WidgetRef ref, Journey journey) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading journey…'), duration: Duration(seconds: 30)),
    );

    try {
      final journeyService = JourneyService();
      final storyService = StoryGuideService();
      final offlineService = OfflineService();

      final allDestinations = await journeyService.fetchAllDestinations();
      print('OFFLINE DEBUG: fetched ${allDestinations.length} destinations');

      final destinationMap = {for (var d in allDestinations) d.id: d};

      final relevantDestinations = journey.stops
          .map((s) => destinationMap[s.destinationId])
          .whereType<Destination>()
          .toList();
      print('OFFLINE DEBUG: ${relevantDestinations.length} relevant destinations for this journey');

      final Map<String, String> stories = {};
      for (final d in relevantDestinations) {
        print('OFFLINE DEBUG: fetching story for ${d.name}');
        stories[d.id] = await storyService.getStory(d);
      }

      await offlineService.cacheJourney(journey: journey, destinations: relevantDestinations, stories: stories);
      print('OFFLINE DEBUG: cached successfully');

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Journey downloaded for offline use')),
        );
      }
    } catch (e) {
      print('OFFLINE DEBUG: error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
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