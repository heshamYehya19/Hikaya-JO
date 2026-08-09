import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/localization/app_locale.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';
import '../../providers/journey_provider.dart';
import '../../providers/main_tab_provider.dart';
import '../../widgets/destination_card.dart';
import '../journey_planner/all_destinations_screen.dart';
import '../journey_planner/destination_detail_screen.dart';
import '../journey_planner/itinerary_screen.dart';
import '../../core/utils/interest_mapping.dart';
import '../journey_planner/journey_route_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocale.of(context).t;
    final user = FirebaseAuth.instance.currentUser;
    final nameAsync = ref.watch(userNameProvider);
    final greetingName = nameAsync.valueOrNull?.trim().isNotEmpty == true
        ? nameAsync.valueOrNull!
        : user?.email?.split('@').first ?? 'there';
    final destinationsAsync = ref.watch(allDestinationsProvider);
    final latestJourneyAsync = ref.watch(latestJourneyProvider);
    final featuredAsync = ref.watch(featuredDestinationProvider);
    final visitedAsync = ref.watch(userVisitedLocationsProvider);

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
                      final destinationMap = {for (var d in destinationsAsync.valueOrNull ?? <Destination>[]) d.id: d};
                      final firstDestination = journey.stops.isNotEmpty ? destinationMap[journey.stops.first.destinationId] : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _ContinueJourneyCard(
                          journey: journey,
                          destination: firstDestination,
                          visitedLocations: visitedAsync.valueOrNull ?? const [],
                          onContinue: () {
                            ref.read(currentJourneyProvider.notifier).state = journey;
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => JourneyRouteScreen(journey: journey)),
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
                      Text(t('home_popular_destinations'), style: Theme.of(context).textTheme.headlineMedium),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AllDestinationsScreen()),
                        ),
                        child: Text(t('home_view_all')),
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
                              t('home_no_destinations'),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          );
                        }
                        final personalized = _personalize(destinations, ref.watch(userInterestsProvider).valueOrNull ?? []);
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: personalized.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => DestinationCard(
                            destination: personalized[i],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DestinationDetailScreen(destinationId: personalized[i].id),
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Center(
                        child: Text(
                          t('home_load_error'),
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
    final t = AppLocale.of(context).t;
    final hasImage = featured?.imageAt(0) != null;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (hasImage)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: featured!.imageAt(0)!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
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
              Text('${t('home_greeting')}, $greetingName',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                t('home_headline'),
                style: const TextStyle(
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
                    child: _QuickAction(icon: Icons.map_outlined, label: t('home_plan_journey'), onTap: onPlanJourney),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(icon: Icons.emoji_events_outlined, label: t('home_hikaya_hunt'), onTap: onHunt),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(icon: Icons.chat_bubble_outline, label: t('home_hikaya_talk'), onTap: onTalk),
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

/// Now shows a real photo, a genuine progress bar (visited stops ÷ total
/// stops, computed from userVisitedLocationsProvider — not a fabricated
/// percentage), a nudging arrow animation, and press feedback on tap.
class _ContinueJourneyCard extends StatefulWidget {
  const _ContinueJourneyCard({
    required this.journey,
    required this.destination,
    required this.visitedLocations,
    required this.onContinue,
  });

  final Journey journey;
  final Destination? destination;
  final List<String> visitedLocations;
  final VoidCallback onContinue;

  @override
  State<_ContinueJourneyCard> createState() => _ContinueJourneyCardState();
}

class _ContinueJourneyCardState extends State<_ContinueJourneyCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.of(context).t;
    final journey = widget.journey;
    final stopIds = journey.stops.map((s) => s.destinationId).toSet();
    final visitedCount = stopIds.where((id) => widget.visitedLocations.contains(id)).length;
    final totalStops = journey.stops.length;
    final progress = totalStops == 0 ? 0.0 : visitedCount / totalStops;
    final hasImage = widget.destination?.imageAt(4) != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onContinue,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              if (hasImage)
                Positioned.fill(
                  child: CachedNetworkImage(imageUrl: widget.destination!.imageAt(4)!, fit: BoxFit.cover),
                )
              else
                const Positioned.fill(child: ColoredBox(color: AppColors.surface)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.background.withOpacity(0.3), AppColors.background.withOpacity(0.93)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t('home_continue_journey'),
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _arrowController,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(_arrowController.value * 4, 0),
                            child: child,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: AppColors.duneGold, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${journey.stops.length} ${t('unit_stops')} · ${(journey.totalDurationMinutes / 60).toStringAsFixed(1)} ${t('unit_hours')}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: AppColors.background.withOpacity(0.5),
                          valueColor: const AlwaysStoppedAnimation(AppColors.duneGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalStops == 0 ? '' : '$visitedCount / $totalStops stops explored',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(onPressed: widget.onContinue, child: Text(t('home_continue_button'))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Destination> _personalize(List<Destination> destinations, List<String> interests) {
  if (interests.isEmpty) return destinations;

  final matchedTypes = matchedDestinationTypes(interests);
  if (matchedTypes.isEmpty) return destinations;

  final matched = destinations.where((d) => matchedTypes.contains(d.type)).toList();
  final rest = destinations.where((d) => !matchedTypes.contains(d.type)).toList();
  return [...matched, ...rest];
}