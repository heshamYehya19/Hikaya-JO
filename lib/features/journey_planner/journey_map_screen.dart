import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/colors.dart';
import '../../core/services/journey_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/directions_service.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';

class JourneyMapScreen extends StatefulWidget {
  final Journey journey;
  const JourneyMapScreen({super.key, required this.journey});

  @override
  State<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends State<JourneyMapScreen> {
  // Minimalist dark theme for Google Maps so the map matches the app's
  // dark/gold look instead of Google's default light tiles. Set via the
  // widget's `style` param (GoogleMapController.setMapStyle is deprecated
  // as of google_maps_flutter 2.6+).
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#17171a"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0d0d0f"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#a3a0a0"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#2e2e33"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#1f1f23"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#a3a0a0"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1a2620"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2a2a2e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#17171a"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8785"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3a3530"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#d4a857"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#1f1f23"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0a1a1a"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4cc9b0"}]}
]
''';

  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final DirectionsService _directionsService = DirectionsService();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  Map<String, Destination> _destinationMap = {};
  Position? _userPosition;
  bool _isLoading = true;
  bool _isLoadingRoute = false;

  String? _selectedStopName;
  String? _routeDistanceText;
  String? _routeDurationText;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = JourneyService();
    final allDestinations = await service.fetchAllDestinations();
    _destinationMap = {for (var d in allDestinations) d.id: d};

    final hasPermission = await _locationService.ensureLocationPermission();
    if (hasPermission) {
      try {
        _userPosition = await _locationService.getCurrentPosition();
      } catch (_) {
        _userPosition = null;
      }
    }

    _buildMarkers();

    setState(() => _isLoading = false);
  }

  void _buildMarkers() {
    final Set<Marker> markers = {};

    for (var i = 0; i < widget.journey.stops.length; i++) {
      final stop = widget.journey.stops[i];
      final destination = _destinationMap[stop.destinationId];
      if (destination == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(destination.id),
          position: LatLng(destination.latitude, destination.longitude),
          infoWindow: InfoWindow(title: '${i + 1}. ${destination.name}', snippet: stop.suggestedTime),
          onTap: () => _selectStop(destination.id, destination.name),
        ),
      );
    }

    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  Future<void> _selectStop(String destinationId, String destinationName, {bool animateCamera = true}) async {
    final destination = _destinationMap[destinationId];
    if (destination == null) return;

    setState(() {
      _selectedStopName = destinationName;
      _polylines.clear();
      _routeDistanceText = null;
      _routeDurationText = null;
      _isLoadingRoute = _userPosition != null;
    });

    if (_userPosition == null) return;

    final origin = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    final dest = LatLng(destination.latitude, destination.longitude);

    final result = await _directionsService.getRoute(origin: origin, destination: dest);

    if (result != null) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('user_to_selected'),
            points: result.routePoints,
            color: AppColors.deepTeal,
            width: 4,
          ),
        );
        _routeDistanceText = result.distanceText;
        _routeDurationText = result.durationText;
        _isLoadingRoute = false;
      });
      if (animateCamera && _mapController != null) {
        _fitBounds([origin, dest, ...result.routePoints]);
      }
    } else {
      // Fallback: Directions API failed or returned no route — show a straight-line estimate instead
      final distanceMeters = _locationService.distanceToTarget(
        userLat: origin.latitude,
        userLng: origin.longitude,
        targetLat: dest.latitude,
        targetLng: dest.longitude,
      );
      final distanceKm = distanceMeters / 1000;
      setState(() {
        _routeDistanceText = '${distanceKm.toStringAsFixed(1)} km (straight-line)';
        _routeDurationText = '~${((distanceKm / 50) * 60).round()} min (estimate)';
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('user_to_selected'),
            points: [origin, dest],
            color: AppColors.textSecondary,
            width: 2,
            patterns: [PatternItem.dash(10), PatternItem.gap(8)],
          ),
        );
        _isLoadingRoute = false;
      });
      if (animateCamera && _mapController != null) {
        _fitBounds([origin, dest]);
      }
    }
  }

  void _fitBounds(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
        80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Journey Map')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            style: _darkMapStyle,
            initialCameraPosition: const CameraPosition(
              target: LatLng(31.9, 35.9),
              zoom: 7,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_markers.isNotEmpty) {
                _fitBounds(_markers.map((m) => m.position).toList());
              }
            },
          ),
          if (_selectedStopName != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.duneLight),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_outlined, color: AppColors.deepTeal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedStopName!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            _isLoadingRoute
                                ? 'Calculating route…'
                                : (_routeDistanceText != null
                                ? '$_routeDistanceText · $_routeDurationText'
                                : 'Enable location to see route'),
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.duneLight),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Journey',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    '${journey.stops.length} Stops · ${(journey.totalDurationMinutes / 60).toStringAsFixed(1)} Hours · ${journey.totalCost.toStringAsFixed(0)} JOD',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: journey.stops.isEmpty
                          ? null
                          : () {
                              final first = journey.stops.first;
                              _selectStop(first.destinationId, first.destinationName);
                            },
                      child: const Text('Start Journey'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
