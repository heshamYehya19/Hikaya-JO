import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/services/location_service.dart';
import '../../models/challenge.dart';
import 'camera_capture_screen.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _locationService = LocationService();
  bool _isChecking = false;
  double? _distanceMeters;
  bool _isWithinRange = false;
  String _status = 'Tap "Check My Location" when you arrive';

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
        _distanceMeters = distance;
        _isWithinRange = withinRange;
        _status = withinRange
            ? '✅ You\'re here! Take a photo to complete this challenge.'
            : 'Keep going — ${(distance / 1000).toStringAsFixed(1)} km to go';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(challenge.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(challenge.destinationName, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Text(challenge.title, style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.deepTeal)),
              const SizedBox(height: 16),
              Text(challenge.description, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.monetization_on_outlined, color: AppColors.duneGold, size: 18),
                  const SizedBox(width: 6),
                  Text('${challenge.rewardCoins} coins · "${challenge.badgeName}" badge',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isWithinRange ? AppColors.teal.withOpacity(0.1) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isWithinRange ? AppColors.teal : AppColors.duneLight),
                ),
                child: Text(_status, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkLocation,
                  child: _isChecking
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}