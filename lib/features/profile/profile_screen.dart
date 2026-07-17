import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/services/journey_service.dart';
import '../../models/journey.dart';
import '../../providers/journey_provider.dart';
import '../journey_planner/itinerary_screen.dart';
import '../hikaya_hunt/rewards_badges_screen.dart';
import '../../core/services/offline_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<Journey> _journeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJourneys();
  }

  Future<void> _loadJourneys() async {
    final offlineService = OfflineService();
    final online = await offlineService.isOnline();

    if (online) {
      try {
        final journeys = await JourneyService().fetchUserJourneys();
        setState(() {
          _journeys = journeys;
          _isLoading = false;
        });
        return;
      } catch (_) {
        // fall through to offline cache below
      }
    }

    // Offline, or the online fetch failed — show whatever's downloaded locally
    final cached = offlineService.getCachedJourneys();
    setState(() {
      _journeys = cached;
      _isLoading = false;
    });
  }

  void _openJourney(Journey journey) {
    ref.read(currentJourneyProvider.notifier).state = journey;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ItineraryScreen()));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.goNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final coins = data['coins'] ?? 0;
          final badges = List<String>.from(data['badges'] ?? []);
          final visited = List<String>.from(data['visitedLocations'] ?? []);
          final name = data['name'] ?? user?.email ?? 'Traveler';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.deepTeal,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            Text(user?.email ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _StatCard(value: '$coins', label: 'Coins', icon: Icons.monetization_on_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(value: '${badges.length}', label: 'Badges', icon: Icons.emoji_events_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(value: '${visited.length}', label: 'Visited', icon: Icons.place_outlined)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RewardsBadgesScreen()),
                      ),
                      icon: const Icon(Icons.emoji_events_outlined),
                      label: const Text('View All Badges'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Your Journeys', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _journeys.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No journeys yet — plan your first one!',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                      : Column(
                    children: _journeys.map((journey) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _openJourney(journey),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.duneLight),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.map_outlined, color: AppColors.deepTeal),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${journey.stops.length} stops · ${(journey.totalDurationMinutes / 60).toStringAsFixed(1)}h',
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(
                                        journey.stops.map((s) => s.destinationName).join(', '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.duneLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.deepTeal, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}