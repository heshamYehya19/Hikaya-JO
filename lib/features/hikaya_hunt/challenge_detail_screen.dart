import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/services/location_service.dart';
import '../../core/services/journey_service.dart';
import '../../models/challenge.dart';
import '../../models/destination.dart';
import 'camera_capture_screen.dart';
import '../../core/services/hunt_service.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _locationService = LocationService();
  bool _isChecking = false;
  bool _isWithinRange = false;
  String _status = 'Tap "Check My Location" when you arrive';
  Destination? _destination;

  @override
  void initState() {
    super.initState();
    _loadDestination();
  }

  Future<void> _loadDestination() async {
    final all = await JourneyService().fetchAllDestinations();
    if (!mounted) return;
    final match = all.where((d) => d.id == widget.challenge.destinationId);
    setState(() => _destination = match.isNotEmpty ? match.first : null);
  }

  Future<void> _checkLocation() async {
    setState(() => _isChecking = true);

    final hasPermission = await _locationService.ensureLocationPermission();
    if (!hasPermission) {
      setState(() {
        _status = 'Location permission needed to unlock this challenge';
        _isChecking = false;
      });
      return;
    }

    try {
      final position = await _locationService.getCurrentPosition();
      final distance = _locationService.distanceToTarget(
        userLat: position.latitude,
        userLng: position.longitude,
        targetLat: widget.challenge.latitude,
        targetLng: widget.challenge.longitude,
      );
      final withinRange = distance <= widget.challenge.radiusMeters;

      setState(() {
        _isWithinRange = withinRange;
        _status = withinRange
            ? "You're here! Take a photo to complete this challenge."
            : 'Keep going — ${distance < 1000 ? '${distance.round()}m' : '${(distance / 1000).toStringAsFixed(1)}km'} to go';
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking location: $e';
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final hasImage = _destination?.imageAt(2) != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: hasImage
                        ? Image.network(
                      _destination!.imageAt(2)!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _HeroFallback(),
                    )
                        : const _HeroFallback(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.destinationName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(challenge.title, style: AppTypography.headline1.copyWith(fontSize: 24)),
                    const SizedBox(height: 14),
                    Text(challenge.description, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textPrimary)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _Pill(
                          icon: Icons.monetization_on_outlined,
                          label: '${challenge.rewardCoins} Coins',
                          color: AppColors.duneGold,
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          icon: Icons.emoji_events_outlined,
                          label: challenge.badgeName,
                          color: AppColors.deepTeal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isWithinRange ? AppColors.teal.withOpacity(0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _isWithinRange ? AppColors.teal : AppColors.duneLight),
                      ),
                      child: Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _isWithinRange ? AppColors.teal : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _checkLocation,
                        child: _isChecking
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                            : const Text('Check My Location'),
                      ),
                    ),
                    if (_isWithinRange) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CameraCaptureScreen(challenge: challenge)),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Take Photo & Unlock'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.duneLight),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                        ),
                      ),
                    ],
                    // Dev-only shortcut, gated behind kDebugMode so it can never
                    // ship in a release build — marked for removal before submission.
                    if (kDebugMode) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () async {
                            final huntService = HuntService();
                            await huntService.completeChallenge(challenge);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('DEV: challenge force-completed')),
                              );
                            }
                          },
                          child: const Text('🛠️ DEV: Force Complete (skip location check)'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
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

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.background],
        ),
      ),
      child: const Center(
        child: Icon(Icons.explore_outlined, size: 48, color: AppColors.duneGold),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}