import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/journey_service.dart';
import '../../core/services/story_guide_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';
import '../../providers/journey_provider.dart';
import 'destination_detail_screen.dart';
import 'journey_map_screen.dart';
import '../../core/services/offline_service.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  Map<String, Destination> _destinationMap = {};

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final all = await JourneyService().fetchAllDestinations();
    if (!mounted) return;
    setState(() => _destinationMap = {for (var d in all) d.id: d});
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(currentJourneyProvider);

    if (journey == null) {
      return const Scaffold(body: Center(child: Text('No journey generated yet')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Journey', style: AppTypography.headline2.copyWith(fontSize: 20)),
                        const Text('Based on your preferences', style: AppTypography.bodySecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.duneLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        value: (journey.totalDurationMinutes / 60).toStringAsFixed(1),
                        label: 'Hours',
                      ),
                    ),
                    const _StatDivider(),
                    Expanded(child: _StatItem(value: '${journey.stops.length}', label: 'Stops')),
                    const _StatDivider(),
                    Expanded(child: _StatItem(value: journey.totalCost.toStringAsFixed(0), label: 'JOD')),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                itemCount: journey.stops.length,
                itemBuilder: (context, index) {
                  final stop = journey.stops[index];
                  final isLast = index == journey.stops.length - 1;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DestinationDetailScreen(destinationId: stop.destinationId)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: AppColors.deepTeal, shape: BoxShape.circle),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: AppColors.background, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (!isLast) Container(width: 2, height: 72, color: AppColors.duneLight),
                          ],
                        ),
                        const SizedBox(width: 10),
                        _StopThumbnail(destination: _destinationMap[stop.destinationId]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stop.destinationName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(stop.notes, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(
                                  '${stop.suggestedTime} · ${stop.durationMinutes} min · ${stop.estimatedCost.toStringAsFixed(0)} JOD',
                                  style: const TextStyle(fontSize: 12, color: AppColors.duneGold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.map_outlined,
                      label: 'View on Map',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => JourneyMapScreen(journey: journey)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.download_outlined,
                      label: 'Download Offline',
                      onTap: () => _downloadForOffline(context, ref, journey),
                    ),
                  ),
                ],
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
      final destinationMap = {for (var d in allDestinations) d.id: d};

      final relevantDestinations = journey.stops
          .map((s) => destinationMap[s.destinationId])
          .whereType<Destination>()
          .toList();

      final Map<String, String> stories = {};
      for (final d in relevantDestinations) {
        stories[d.id] = await storyService.getStory(d);
      }

      await offlineService.cacheJourney(journey: journey, destinations: relevantDestinations, stories: stories);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Journey downloaded for offline use')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }
}

/// Small thumbnail for each stop. Falls back to a gradient + type icon
/// when the destination has no imageUrls yet — same pattern as DestinationCard.
class _StopThumbnail extends StatelessWidget {
  final Destination? destination;
  const _StopThumbnail({required this.destination});

  IconData get _typeIcon {
    switch (destination?.type) {
      case 'natural':
        return Icons.landscape_outlined;
      case 'cultural':
        return Icons.temple_buddhist_outlined;
      case 'historical':
      default:
        return Icons.account_balance_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = destination?.imageUrls.isNotEmpty == true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: hasImage
            ? Image.network(destination!.imageUrls.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.background],
        ),
      ),
      child: Icon(_typeIcon, size: 20, color: AppColors.duneGold),
    );
  }
}

/// Both footer buttons share this so they're always identical in
/// size and color — only the icon/label differ.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepTeal,
        foregroundColor: AppColors.background,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.deepTeal)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.duneLight);
  }
}