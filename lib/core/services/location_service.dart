import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Checks permission status and requests it if not yet granted.
  /// Returns true if permission is granted and location services are usable.
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

  /// Gets the user's current position (one-off read).
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Streams live position updates — used for continuous geofence checking.
  Stream<Position> watchPosition() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters — only emit updates after 5m of movement
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Returns distance in meters between the user and a target point.
  double distanceToTarget({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
  }) {
    return Geolocator.distanceBetween(userLat, userLng, targetLat, targetLng);
  }

  /// Core geofence check — is the user within [radiusMeters] of the target?
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