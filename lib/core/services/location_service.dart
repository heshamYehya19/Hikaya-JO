import 'dart:io';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  LocationSettings _buildOneShotSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: true,
        timeLimit: const Duration(seconds: 10),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  // No timeLimit here on purpose — a continuous stream (arrival detection,
  // the Find Your Way compass) needs to keep listening indefinitely, not
  // silently die the moment 10 seconds pass without a qualifying move —
  // e.g. walking slowly, or briefly indoors with weaker GPS reception.
  LocationSettings _buildStreamSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: _buildOneShotSettings(),
    );
  }

  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(locationSettings: _buildStreamSettings());
  }

  double distanceToTarget({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
  }) {
    return Geolocator.distanceBetween(userLat, userLng, targetLat, targetLng);
  }

  bool isWithinGeofence({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
    double radiusMeters = 50,
  }) {
    final distance = distanceToTarget(
      userLat: userLat,
      userLng: userLng,
      targetLat: targetLat,
      targetLng: targetLng,
    );
    return distance <= radiusMeters;
  }
}