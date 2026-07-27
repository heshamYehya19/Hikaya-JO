import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/localization/app_locale.dart';
import '../../core/services/journey_service.dart';
import '../../models/journey.dart';
import '../../models/destination.dart';
import '../../providers/journey_provider.dart';
import '../journey_planner/itinerary_screen.dart';
import '../hikaya_hunt/rewards_badges_screen.dart';
import '../../core/services/offline_service.dart';
import '../../providers/main_tab_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<Journey> _journeys = [];
  bool _isLoading = true;

  List<Journey> _downloadedJourneys = [];
  bool _isLoadingDownloaded = true;

  Map<String, Destination> _destinationMap = {};

  @override
  void initState() {
    super.initState();
    _loadJourneys();
    _loadDownloadedJourneys();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final all = await JourneyService().fetchAllDestinations();
    if (!mounted) return;
    setState(() => _destinationMap = {for (var d in all) d.id: d});
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

    final cached = offlineService.getCachedJourneys();
    setState(() {
      _journeys = cached;
      _isLoading = false;
    });
  }

  /// Always reads straight from the local Hive cache, online or not — this
  /// is what actually answers "what's downloaded on this device", separate
  /// from _loadJourneys() above which shows all journeys when online.
  Future<void> _loadDownloadedJourneys() async {
    final cached = OfflineService().getCachedJourneys();
    setState(() {
      _downloadedJourneys = cached;
      _isLoadingDownloaded = false;
    });
  }

  void _openJourney(Journey journey) {
    ref.read(currentJourneyProvider.notifier).state = journey;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ItineraryScreen()));
  }

  Future<void> _logout() async {
    ref.read(mainTabIndexProvider.notifier).state = 0;
    await FirebaseAuth.instance.signOut();
    if (mounted) context.goNamed('login');
  }

  void _openSettings(String appLanguage, String? userId) {
    final t = AppLocale.of(context).t;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: AppTypography.headline2.copyWith(fontSize: 18)),
              const SizedBox(height: 20),
              Text(t('profile_app_language'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(t('profile_app_language_subtitle'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AppLanguageOption(
                      label: 'English',
                      selected: appLanguage == 'en',
                      onTap: () => FirebaseFirestore.instance.collection('users').doc(userId).update({'appLanguage': 'en'}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AppLanguageOption(
                      label: 'العربية',
                      selected: appLanguage == 'ar',
                      onTap: () => FirebaseFirestore.instance.collection('users').doc(userId).update({'appLanguage': 'ar'}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _logout();
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text('Log Out', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _badgeIcon(String badgeName) {
    final n = badgeName.toLowerCase();
    if (n.contains('explor')) return Icons.explore_outlined;
    if (n.contains('pilgrim') || n.contains('mosque')) return Icons.mosque_outlined;
    if (n.contains('gem') || n.contains('hidden')) return Icons.diamond_outlined;
    if (n.contains('travel') || n.contains('buoyant') || n.contains('water')) return Icons.water_outlined;
    if (n.contains('history')) return Icons.account_balance_outlined;
    if (n.contains('adventure') || n.contains('hik')) return Icons.hiking_outlined;
    return Icons.emoji_events_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.of(context).t;
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userId == null
          ? Center(child: Text(t('profile_not_logged_in')))
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final coins = data['coins'] ?? 0;
          final badges = List<String>.from(data['badges'] ?? []);
          final visited = List<String>.from(data['visitedLocations'] ?? []);
          final name = data['name'] ?? user?.email ?? 'Traveler';
          final appLanguage = (data['appLanguage'] as String?) ?? 'en';
          final level = (coins / 100).floor() + 1; // derived, not stored — purely a display touch

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t('profile_title'), style: AppTypography.headline2.copyWith(fontSize: 20)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _openSettings(appLanguage, userId),
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.deepTeal,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.background, fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.duneGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.duneGold.withOpacity(0.4)),
                          ),
                          child: Text(
                            'Traveler Level $level',
                            style: const TextStyle(color: AppColors.duneGold, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.duneLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _StatItem(value: '$coins', label: t('profile_coins'))),
                        const _StatDivider(),
                        Expanded(child: _StatItem(value: '${badges.length}', label: t('profile_badges'))),
                        const _StatDivider(),
                        Expanded(child: _StatItem(value: '${visited.length}', label: t('profile_visited'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Achievements', style: AppTypography.headline2.copyWith(fontSize: 18)),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RewardsBadgesScreen()),
                        ),
                        child: Text(t('profile_view_all_badges')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  badges.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No badges yet — complete a Hikaya Hunt challenge to earn one', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  )
                      : SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: badges.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => SizedBox(
                        width: 68,
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.duneGold.withOpacity(0.4)),
                              ),
                              child: Icon(_badgeIcon(badges[i]), color: AppColors.duneGold, size: 24),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              badges[i],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(t('profile_your_journeys'), style: AppTypography.headline2.copyWith(fontSize: 18)),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.deepTeal))
                      : _journeys.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(t('profile_no_journeys'), style: const TextStyle(color: AppColors.textSecondary)),
                  )
                      : Column(
                    children: _journeys.map((journey) => _JourneyRow(
                      journey: journey,
                      destination: _destinationMap[journey.stops.isNotEmpty ? journey.stops.first.destinationId : ''],
                      onTap: () => _openJourney(journey),
                    )).toList(),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Icon(Icons.download_done_rounded, color: AppColors.deepTeal, size: 20),
                      const SizedBox(width: 8),
                      Text('Downloaded Journeys', style: AppTypography.headline2.copyWith(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Saved on this device — available even without a connection',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingDownloaded
                      ? const Center(child: CircularProgressIndicator(color: AppColors.deepTeal))
                      : _downloadedJourneys.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Nothing downloaded yet — tap "Download Offline" on any journey to save it here',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                      : Column(
                    children: _downloadedJourneys.map((journey) => _JourneyRow(
                      journey: journey,
                      destination: _destinationMap[journey.stops.isNotEmpty ? journey.stops.first.destinationId : ''],
                      onTap: () => _openJourney(journey),
                      accent: true,
                    )).toList(),
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

class _JourneyRow extends StatelessWidget {
  final Journey journey;
  final Destination? destination;
  final VoidCallback onTap;
  final bool accent;
  const _JourneyRow({required this.journey, required this.destination, required this.onTap, this.accent = false});

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = destination?.imageAt(2);
    final title = journey.stops.isNotEmpty ? '${journey.stops.first.destinationName} Adventure' : 'Journey';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent ? AppColors.deepTeal.withOpacity(0.06) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent ? AppColors.deepTeal.withOpacity(0.3) : AppColors.duneLight),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
                      : _fallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(_formatDate(journey.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Icon(Icons.map_outlined, color: AppColors.duneGold, size: 20),
    );
  }
}

class _AppLanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AppLanguageOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepTeal.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.deepTeal : AppColors.duneLight),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? AppColors.deepTeal : AppColors.textPrimary),
          ),
        ),
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