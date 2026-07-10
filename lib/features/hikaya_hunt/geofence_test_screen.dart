import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/colors.dart';

class GeofenceTestScreen extends StatefulWidget {
  const GeofenceTestScreen({super.key});

  @override
  State<GeofenceTestScreen> createState() => _GeofenceTestScreenState();
}

class _GeofenceTestScreenState extends State<GeofenceTestScreen> {
  final _locationService = LocationService();

  // TEST TARGET: Amman Citadel coordinates — swap for wherever you're
  // physically testing from, so you can actually walk into range
  static const double targetLat = 31.882402;
  static const double targetLng = 36.005780;
  static const double radiusMeters = 50; // or whatever real value makes sense for a Hikaya Hunt challenge

  String _status = 'Not checked yet';
  double? _distance;
  bool _isChecking = false;

  Future<void> _checkGeofence() async {
    setState(() => _isChecking = true);

    final hasPermission = await _locationService.ensureLocationPermission();
    if (!hasPermission) {
      setState(() {
        _status = 'Location permission denied';
        _isChecking = false;
      });
      return;
    }

    try {
      final position = await _locationService.getCurrentPosition();
      final distance = _locationService.distanceToTarget(
        userLat: position.latitude,
        userLng: position.longitude,
        targetLat: targetLat,
        targetLng: targetLng,
      );
      final isInside = distance <= radiusMeters;

      setState(() {
        _distance = distance;
        _status = isInside ? '✅ UNLOCKED — you are within range!' : '📍 Too far — keep moving closer';
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geofence Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              if (_distance != null) ...[
                const SizedBox(height: 12),
                Text('Distance: ${_distance!.toStringAsFixed(1)} m', style: TextStyle(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isChecking ? null : _checkGeofence,
                child: _isChecking ? const CircularProgressIndicator(color: Colors.white) : const Text('Check My Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}