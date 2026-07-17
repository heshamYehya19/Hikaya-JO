import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';
import '../../models/destination.dart';
import '../../providers/journey_provider.dart';
import '../../providers/main_tab_provider.dart';
import '../../widgets/destination_card.dart';
import '../journey_planner/all_destinations_screen.dart';
import '../journey_planner/destination_detail_screen.dart';
import '../journey_planner/itinerary_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final greetingName = user?.email?.split('@').first ?? 'there';
    final destinationsAsync = ref.watch(allDestinationsProvider);
    final latestJourneyAsync = ref.watch(latestJourneyProvider);
    final featuredAsync = ref.watch(featuredDestinationProvider);

    void goToTab(int index) => ref.read(mainTabIndexProvider.notifier).state = index;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeroHeader(
              greetingName: greetingName,
              featured: featuredAsync.valueOrNull,
              onPlanJourney: () => goToTab(1),
              onHunt: () => goToTab(2),
              onTalk: () => goToTab(3),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  latestJourneyAsync.when(
                    data: (journey) {
                      if (journey == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _ContinueJourneyCard(
                          stopCount: journey.stops.length,
                          totalHours: (journey.totalDurationMinutes / 60),
                          onContinue: () {
                            ref.read(currentJourneyProvider.notifier).state = journey;
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ItineraryScreen()),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Popular Destinations', style: Theme.of(context).textTheme.headlineMedium),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AllDestinationsScreen()),
                        ),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: destinationsAsync.when(
                      data: (destinations) {
                        if (destinations.isEmpty) {
                          return Center(
                            child: Text(
                              'No destinations yet — run /seed',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: destinations.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => DestinationCard(
                            destination: destinations[i],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DestinationDetailScreen(destinationId: destinations[i].id),
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Center(
                        child: Text(
                          "Couldn't load destinations",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
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
}

/// Full-bleed header: greeting + headline over the featured destination's
/// photo (fetched from Firestore via featuredDestinationProvider — see
/// journey_provider.dart). Falls back to a plain gradient if that
/// destination doesn't have an imageUrls entry yet, so this never breaks
/// before you've uploaded photos.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.greetingName,
    required this.featured,
    required this.onPlanJourney,
    required this.onHunt,
    required this.onTalk,
  });

  final String greetingName;
  final Destination? featured;
  final VoidCallback onPlanJourney;
  final VoidCallback onHunt;
  final VoidCallback onTalk;

  @override
  Widget build(BuildContext context) {
    final hasImage = featured != null && featured!.imageUrls.isNotEmpty;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (hasImage)
          Positioned.fill(
            child: Image.network(
              featured!.imageUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          decoration: BoxDecoration(
            gradient: hasImage
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withOpacity(0.3),
                      AppColors.background.withOpacity(0.95),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surfaceElevated, AppColors.background],
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good Morning, $greetingName',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 6),
              const Text(
                "Discover Jordan's Hidden Stories",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(icon: Icons.map_outlined, label: 'Plan a Journey', onTap: onPlanJourney),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(icon: Icons.emoji_events_outlined, label: 'Hikaya Hunt', onTap: onHunt),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(icon: Icons.chat_bubble_outline, label: 'Hikaya Talk', onTap: onTalk),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.duneLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.deepTeal, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the user's most recent saved journey. There's no completion-percent
/// field on the Journey model yet, so this shows real stop count / duration
/// instead of a fabricated progress bar — add a `completedStops` field to
/// the model if you want the literal "45% Completed" bar from the reference.
class _ContinueJourneyCard extends StatelessWidget {
  const _ContinueJourneyCard({
    required this.stopCount,
    required this.totalHours,
    required this.onContinue,
  });

  final int stopCount;
  final double totalHours;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.duneLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Continue Your Journey',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            '$stopCount stops · ${totalHours.toStringAsFixed(1)} hours',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: onContinue, child: const Text('Continue')),
          ),
        ],
      ),
    );
  }
}
