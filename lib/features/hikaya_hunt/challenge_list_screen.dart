import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/services/hunt_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/journey_service.dart';
import '../../models/challenge.dart';
import '../../models/destination.dart';
import 'challenge_detail_screen.dart';
import 'rewards_badges_screen.dart';

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

    final Map<String, double> distances = {};
    final hasPermission = await _locationService.ensureLocationPermission();

    if (hasPermission) {
      try {
        final pos = await _locationService.getCurrentPosition();
        for (final c in challenges) {
          distances[c.id] = _locationService.distanceToTarget(
            userLat: pos.latitude,
            userLng: pos.longitude,
            targetLat: c.latitude,
            targetLng: c.longitude,
          );
        }
      } catch (e) {}
    }

    challenges.sort((a, b) => (distances[a.id] ?? double.infinity).compareTo(distances[b.id] ?? double.infinity));

    setState(() {
      _challenges = challenges;
      _completedIds = completed;
      _distancesMeters = distances;
      _destinationMap = {for (var d in allDestinations) d.id: d};
      _isLoading = false;
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

  String _difficultyLabel(_Difficulty d) => switch (d) {
    _Difficulty.easy => 'Easy',
    _Difficulty.medium => 'Medium',
    _Difficulty.hard => 'Hard',
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
    final visible =
    _filter == null ? _challenges : _challenges.where((c) => _difficultyOf(c) == _filter).toList();

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
                        Text('Hikaya Hunt', style: AppTypography.headline1.copyWith(fontSize: 24)),
                        const Text('Explore challenges around you', style: AppTypography.bodySecondary),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const RewardsBadgesScreen()))
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
                  _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Easy',
                    selected: _filter == _Difficulty.easy,
                    onTap: () => setState(() => _filter = _Difficulty.easy),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Medium',
                    selected: _filter == _Difficulty.medium,
                    onTap: () => setState(() => _filter = _Difficulty.medium),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Hard',
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
                child: visible.isEmpty
                    ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Text('No challenges in this range', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final challenge = visible[index];
                    final isDone = _completedIds.contains(challenge.id);
                    final difficulty = _difficultyOf(challenge);
                    final destination = _destinationMap[challenge.destinationId];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ChallengeDetailScreen(challenge: challenge)))
                            .then((_) => _load()),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDone ? AppColors.teal : AppColors.duneLight,
                              width: isDone ? 1.5 : 1,
                            ),
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
                                    Text(
                                      challenge.title,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(challenge.destinationName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _difficultyColor(difficulty).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _difficultyLabel(difficulty),
                                            style: TextStyle(color: _difficultyColor(difficulty), fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isDone ? 'Completed' : '+${challenge.rewardCoins} coins',
                                          style: TextStyle(
                                            color: isDone ? AppColors.teal : AppColors.duneGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isDone && _distancesMeters[challenge.id] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 2),
                                          Text(_formatDistance(_distancesMeters[challenge.id]), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                  },
                ),
              ),
            ),
          ],
        ),
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
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
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
      decoration: BoxDecoration(
        color: isDone ? AppColors.teal.withOpacity(0.15) : AppColors.surfaceElevated,
      ),
      child: Icon(
        isDone ? Icons.check_circle : Icons.explore_outlined,
        color: isDone ? AppColors.teal : AppColors.duneGold,
        size: 20,
      ),
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
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}