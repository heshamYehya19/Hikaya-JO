import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/localization/app_locale.dart';
import '../../core/router/page_transitions.dart';
import '../../core/services/hunt_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/journey_service.dart';
import '../../models/challenge.dart';
import '../../models/destination.dart';
import 'challenge_detail_screen.dart';
import 'rewards_badges_screen.dart';
import '../journey_planner/destination_detail_screen.dart';

enum _Difficulty { easy, medium, hard }

class ChallengeListScreen extends StatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> {
  final _huntService = HuntService();
  final _locationService = LocationService();

  List<Challenge> _challenges = [];
  Set<String> _completedIds = {};
  Set<String> _visitedDestinationIds = {};
  Map<String, double> _distancesMeters = {};
  Map<String, Destination> _destinationMap = {};
  bool _isLoading = true;
  _Difficulty? _filter; // null = All

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final challenges = await _huntService.fetchChallenges();
    final completed = await _huntService.fetchCompletedChallengeIds();
    final allDestinations = await JourneyService().fetchAllDestinations();

    Set<String> visitedIds = {};
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        visitedIds = Set<String>.from(userDoc.data()?['visitedLocations'] ?? []);
      } catch (_) {
        // Offline or read failed — treat as "nothing unlocked yet" rather than crash.
      }
    }

    if (!mounted) return;

    // Show the list right away — distance/sorting is a nice-to-have that
    // fills in a moment later, not something worth blocking the whole
    // screen on. A slow or hung GPS fix (flaky provider, no fix indoors)
    // must never leave this screen stuck on a spinner forever.
    setState(() {
      _challenges = challenges;
      _completedIds = completed;
      _visitedDestinationIds = visitedIds;
      _destinationMap = {for (var d in allDestinations) d.id: d};
      _isLoading = false;
    });

    unawaited(_loadDistances(challenges));
  }

  Future<void> _loadDistances(List<Challenge> challenges) async {
    final hasPermission = await _locationService.ensureLocationPermission();
    if (!hasPermission) return;

    Position pos;
    try {
      pos = await _locationService.getCurrentPosition();
    } catch (e) {
      return;
    }
    if (!mounted) return;

    final distances = <String, double>{};
    for (final c in challenges) {
      distances[c.id] = _locationService.distanceToTarget(
        userLat: pos.latitude,
        userLng: pos.longitude,
        targetLat: c.latitude,
        targetLng: c.longitude,
      );
    }

    final sorted = List<Challenge>.from(challenges)
      ..sort((a, b) => (distances[a.id] ?? double.infinity).compareTo(distances[b.id] ?? double.infinity));

    setState(() {
      _challenges = sorted;
      _distancesMeters = distances;
    });
  }

  _Difficulty _difficultyOf(Challenge c) {
    switch (c.difficulty.toLowerCase()) {
      case 'medium':
        return _Difficulty.medium;
      case 'hard':
        return _Difficulty.hard;
      case 'easy':
      default:
        return _Difficulty.easy;
    }
  }

  // A completed challenge is always treated as unlocked too, even in the
  // unlikely case its destination somehow isn't in visitedLocations — you
  // can't complete a challenge without having been there.
  bool _isUnlocked(Challenge c) => _completedIds.contains(c.id) || _visitedDestinationIds.contains(c.destinationId);

  String _difficultyLabel(_Difficulty d, String Function(String) t) => switch (d) {
    _Difficulty.easy => t('hunt_filter_easy'),
    _Difficulty.medium => t('hunt_filter_medium'),
    _Difficulty.hard => t('hunt_filter_hard'),
  };

  Color _difficultyColor(_Difficulty d) => switch (d) {
    _Difficulty.easy => AppColors.success,
    _Difficulty.medium => AppColors.warning,
    _Difficulty.hard => AppColors.error,
  };

  String _formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '${meters.round()}m away';
    return '${(meters / 1000).toStringAsFixed(1)}km away';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.of(context).t;
    final filtered =
    _filter == null ? _challenges : _challenges.where((c) => _difficultyOf(c) == _filter).toList();

    final unlocked = filtered.where(_isUnlocked).toList();
    final locked = filtered.where((c) => !_isUnlocked(c)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('hunt_title'), style: AppTypography.headline1.copyWith(fontSize: 24)),
                        Text(t('hunt_subtitle'), style: AppTypography.bodySecondary),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context)
                        .push(smoothPageRoute(const RewardsBadgesScreen()))
                        .then((_) => _load()),
                    icon: const Icon(Icons.emoji_events_outlined, color: AppColors.duneGold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(label: t('hunt_filter_all'), selected: _filter == null, onTap: () => setState(() => _filter = null)),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: t('hunt_filter_easy'),
                    selected: _filter == _Difficulty.easy,
                    onTap: () => setState(() => _filter = _Difficulty.easy),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: t('hunt_filter_medium'),
                    selected: _filter == _Difficulty.medium,
                    onTap: () => setState(() => _filter = _Difficulty.medium),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: t('hunt_filter_hard'),
                    selected: _filter == _Difficulty.hard,
                    onTap: () => setState(() => _filter = _Difficulty.hard),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.deepTeal))
                  : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.deepTeal,
                backgroundColor: AppColors.surface,
                child: (unlocked.isEmpty && locked.isEmpty)
                    ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Text(t('hunt_empty'), style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                )
                    : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    if (unlocked.isNotEmpty) ...[
                      _SectionHeader(icon: Icons.explore, label: '🏆 Ready to Hunt', color: AppColors.duneGold),
                      const SizedBox(height: 10),
                      ...unlocked.map((challenge) => _UnlockedCard(
                        challenge: challenge,
                        destination: _destinationMap[challenge.destinationId],
                        isDone: _completedIds.contains(challenge.id),
                        difficultyLabel: _difficultyLabel(_difficultyOf(challenge), t),
                        difficultyColor: _difficultyColor(_difficultyOf(challenge)),
                        distanceLabel: _formatDistance(_distancesMeters[challenge.id]),
                        onTap: () => Navigator.of(context)
                            .push(smoothPageRoute(ChallengeDetailScreen(
                          challenge: challenge,
                          isCompleted: _completedIds.contains(challenge.id),
                        )))
                            .then((_) => _load()),
                      )),
                      const SizedBox(height: 24),
                    ],
                    if (locked.isNotEmpty) ...[
                      _SectionHeader(icon: Icons.map_outlined, label: '🗺️ Discover to Unlock', color: AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Listen to a destination\'s story in person to reveal what\'s waiting there.',
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12),
                        ),
                      ),
                      ...locked.map((challenge) => _LockedCard(
                        challenge: challenge,
                        destination: _destinationMap[challenge.destinationId],
                        onTap: () => Navigator.of(context).push(
                          smoothPageRoute(DestinationDetailScreen(destinationId: challenge.destinationId)),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _UnlockedCard extends StatelessWidget {
  final Challenge challenge;
  final Destination? destination;
  final bool isDone;
  final String difficultyLabel;
  final Color difficultyColor;
  final String distanceLabel;
  final VoidCallback onTap;

  const _UnlockedCard({
    required this.challenge,
    required this.destination,
    required this.isDone,
    required this.difficultyLabel,
    required this.difficultyColor,
    required this.distanceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDone ? AppColors.teal : AppColors.duneLight, width: isDone ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChallengeThumbnail(destination: destination, isDone: isDone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(challenge.destinationName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: difficultyColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text(difficultyLabel, style: TextStyle(color: difficultyColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDone ? 'Completed' : '+${challenge.rewardCoins} coins',
                          style: TextStyle(color: isDone ? AppColors.teal : AppColors.duneGold, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (!isDone && distanceLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(distanceLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
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

/// Dimmed, obscured card for a challenge you haven't unlocked yet. The
/// reward and difficulty are intentionally hidden — tapping goes to the
/// destination's info page, not into Story Mode directly, since that stays
/// gated behind actually arriving there.
class _LockedCard extends StatelessWidget {
  final Challenge challenge;
  final Destination? destination;
  final VoidCallback onTap;
  const _LockedCard({required this.challenge, required this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: 0.55,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.duneLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LockedThumbnail(destination: destination),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•••••••••', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(challenge.destinationName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.textSecondary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Text('🔒 Locked', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Listen to the story at ${challenge.destinationName} to unlock',
                        style: TextStyle(color: AppColors.textSecondary.withOpacity(0.9), fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedThumbnail extends StatefulWidget {
  final Destination? destination;
  const _LockedThumbnail({required this.destination});

  @override
  State<_LockedThumbnail> createState() => _LockedThumbnailState();
}

class _LockedThumbnailState extends State<_LockedThumbnail> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.destination?.imageAt(3);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 44,
              height: 44,
              child: imageUrl != null
                  ? ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.darken),
                child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.surfaceElevated)),
              )
                  : Container(color: AppColors.surfaceElevated),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Opacity(opacity: 0.6 + (_pulse.value * 0.4), child: child),
              child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeThumbnail extends StatelessWidget {
  final Destination? destination;
  final bool isDone;
  const _ChallengeThumbnail({required this.destination, required this.isDone});

  @override
  Widget build(BuildContext context) {
    final imageUrl = destination?.imageAt(3);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 44,
              height: 44,
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _fallback())
                  : _fallback(),
            ),
          ),
          if (isDone)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppColors.teal, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(color: isDone ? AppColors.teal.withOpacity(0.15) : AppColors.surfaceElevated),
      child: Icon(isDone ? Icons.check_circle : Icons.explore_outlined, color: isDone ? AppColors.teal : AppColors.duneGold, size: 20),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepTeal : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.deepTeal : AppColors.duneLight),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? AppColors.background : AppColors.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}