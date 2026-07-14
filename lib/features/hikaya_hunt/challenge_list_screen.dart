import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/services/hunt_service.dart';
import '../../core/services/location_service.dart';
import '../../models/challenge.dart';
import 'challenge_detail_screen.dart';
import 'rewards_badges_screen.dart';

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
  Map<String, double> _distances = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final challenges = await _huntService.fetchChallenges();

    final completed = await _huntService.fetchCompletedChallengeIds();

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
          ) /
              1000;
        }
      } catch (e) {
      }
    }

    challenges.sort((a, b) => (distances[a.id] ?? 999999).compareTo(distances[b.id] ?? 999999));

    setState(() {
      _challenges = challenges;
      _completedIds = completed;
      _distances = distances;
      _isLoading = false;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hikaya Hunt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const RewardsBadgesScreen()))
                .then((_) => _load()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _challenges.length,
          itemBuilder: (context, index) {
            final challenge = _challenges[index];
            final isDone = _completedIds.contains(challenge.id);
            final distance = _distances[challenge.id];

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
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDone ? AppColors.teal : AppColors.duneLight, width: isDone ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDone ? Icons.check_circle : Icons.emoji_events_outlined,
                        color: isDone ? AppColors.teal : AppColors.duneGold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(challenge.destinationName, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              isDone
                                  ? 'Completed'
                                  : distance != null
                                  ? '${distance.toStringAsFixed(1)} km away · +${challenge.rewardCoins} coins'
                                  : '+${challenge.rewardCoins} coins',
                              style: TextStyle(
                                color: isDone ? AppColors.teal : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
    );
  }
}