import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/localization/app_locale.dart';
import '../../core/services/app_prefs_service.dart';
import '../../core/services/arrival_watcher_service.dart';
import '../../core/services/journey_service.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';
import '../../providers/main_tab_provider.dart';
import '../../providers/journey_provider.dart';
import '../../widgets/feature_tour_overlay.dart';
import '../../widgets/arrival_reveal_overlay.dart';
import '../journey_planner/story_mode_screen.dart';
import 'home_screen.dart';
import '../journey_planner/journey_planner_input_screen.dart';
import '../hikaya_hunt/challenge_list_screen.dart';
import '../hikaya_talk/hikaya_talk_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/offline_banner.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _screens = [
    HomeScreen(),
    JourneyPlannerInputScreen(),
    ChallengeListScreen(),
    HikayaTalkScreen(),
    ProfileScreen(),
  ];

  bool _showTour = false;

  final _arrivalWatcher = ArrivalWatcherService();
  Destination? _arrivedDestination;
  String? _watchedJourneyId;

  @override
  void initState() {
    super.initState();
    if (!AppPrefsService().hasSeenFeatureTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showTour = true);
      });
    }
  }

  void _finishTour() {
    AppPrefsService().markFeatureTourSeen();
    setState(() => _showTour = false);
  }

  /// Starts/stops arrival watching to track whichever journey is currently
  /// active. Only re-resolves stops and restarts the watcher when the
  /// journey actually changes, so this is safe to call on every build.
  Future<void> _syncArrivalWatcher(Journey? journey) async {
    if (journey == null) {
      if (_watchedJourneyId != null) {
        await _arrivalWatcher.stop();
        _watchedJourneyId = null;
      }
      return;
    }
    if (_watchedJourneyId == journey.id) return;

    _watchedJourneyId = journey.id;
    _arrivalWatcher.resetNotified();

    final allDestinations = await JourneyService().fetchAllDestinations();
    final destinationMap = {for (var d in allDestinations) d.id: d};
    final stops = journey.stops.map((s) => destinationMap[s.destinationId]).whereType<Destination>().toList();

    await _arrivalWatcher.start(
      stopsWithCoordinates: stops,
      onArrival: (destination) {
        if (mounted) setState(() => _arrivedDestination = destination);
      },
    );
  }

  @override
  void dispose() {
    _arrivalWatcher.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabIndexProvider);
    final t = AppLocale.of(context).t;

    ref.listen<Journey?>(currentJourneyProvider, (previous, next) {
      _syncArrivalWatcher(next);
    });

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const OfflineBanner(),
              Expanded(child: IndexedStack(index: currentIndex, children: _screens)),
            ],
          ),
          if (_showTour)
            FeatureTourOverlay(
              onFinished: _finishTour,
              steps: const [
                TourStep(icon: Icons.home_outlined, title: 'Home Base', description: "Your gateway to Jordan's best-kept secrets — trending spots, and pick up right where you left off."),
                TourStep(icon: Icons.map_outlined, title: 'Plan a Journey', description: "Tell us what excites you, and let Hikaya craft the perfect route through Jordan's history, nature, and flavor."),
                TourStep(icon: Icons.emoji_events_outlined, title: 'Hikaya Hunt', description: 'Turn every landmark into an adventure! Track down hidden gates, snap your proof, and watch the coins roll in.'),
                TourStep(icon: Icons.chat_bubble_outline, title: 'Hikaya Talk', description: "Never get lost in translation — speak freely and we'll bridge the gap in real time, both ways."),
                TourStep(icon: Icons.person_outline, title: 'Your Story', description: 'Every coin, badge, and journey you conquer — all tracked in one place, just for you.'),
              ],
            ),
          if (_arrivedDestination != null)
            ArrivalRevealOverlay(
              destination: _arrivedDestination!,
              onDismiss: () => setState(() => _arrivedDestination = null),
              onListen: () {
                final destination = _arrivedDestination!;
                setState(() => _arrivedDestination = null);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoryModeScreen(destination: destination)));
              },
            ),
          if (kDebugMode)
            Positioned(
              right: 16,
              bottom: 90,
              child: FloatingActionButton.small(
                heroTag: 'debug_arrival',
                backgroundColor: AppColors.error,
                onPressed: _debugTriggerArrival,
                child: const Icon(Icons.location_on, color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(mainTabIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.deepTeal,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: t('nav_home')),
          BottomNavigationBarItem(icon: const Icon(Icons.map_outlined), label: t('nav_journey')),
          BottomNavigationBarItem(icon: const Icon(Icons.emoji_events_outlined), label: t('nav_hunt')),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), label: t('nav_talk')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: t('nav_profile')),
        ],
      ),
    );
  }
  void _debugTriggerArrival() async {
    final journey = ref.read(currentJourneyProvider);
    if (journey == null || journey.stops.isEmpty) return;
    final allDestinations = await JourneyService().fetchAllDestinations();
    final destinationMap = {for (var d in allDestinations) d.id: d};
    final first = destinationMap[journey.stops.first.destinationId];
    if (first != null && mounted) setState(() => _arrivedDestination = first);
  }
}