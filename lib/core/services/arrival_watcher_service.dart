import 'dart:async';
import 'location_service.dart';
import '../../models/destination.dart';

/// Watches the device's position against a journey's stops while the app
/// is open and reports arrivals — exactly once per stop, even if the user
/// lingers in range. Foreground-only by design: relies on Geolocator's
/// position stream, which only runs while this service is alive (i.e. the
/// app process is running) — no background/closed-app wake-up, per the
/// reliability tradeoff this was built around.
class ArrivalWatcherService {
  final LocationService _locationService;
  ArrivalWatcherService({LocationService? locationService}) : _locationService = locationService ?? LocationService();

  StreamSubscription<dynamic>? _subscription;
  final Set<String> _notified = {};

  static const double _arrivalRadiusMeters = 150; // "you're generally at this place" — looser than a Hunt photo-challenge geofence

  Future<void> start({
    required List<Destination> stopsWithCoordinates,
    required void Function(Destination destination) onArrival,
  }) async {
    await stop(); // don't stack subscriptions if start() gets called again

    final hasPermission = await _locationService.ensureLocationPermission();
    if (!hasPermission) return;

    _subscription = _locationService.watchPosition().listen((position) {
      for (final destination in stopsWithCoordinates) {
        if (_notified.contains(destination.id)) continue;

        final within = _locationService.isWithinGeofence(
          userLat: position.latitude,
          userLng: position.longitude,
          targetLat: destination.latitude,
          targetLng: destination.longitude,
          radiusMeters: _arrivalRadiusMeters,
        );

        if (within) {
          _notified.add(destination.id);
          onArrival(destination);
        }
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Call when the active journey changes so a stop already visited on a
  /// previous journey can trigger again on a new one.
  void resetNotified() => _notified.clear();
}