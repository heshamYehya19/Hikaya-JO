import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/colors.dart';
import '../../core/services/journey_service.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';

class JourneyMapScreen extends StatefulWidget {
  final Journey journey;
  const JourneyMapScreen({super.key, required this.journey});

  @override
  State<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends State<JourneyMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _buildMapData();
  }

  Future<void> _buildMapData() async {
    final service = JourneyService();
    final allDestinations = await service.fetchAllDestinations();
    final destinationMap = {for (var d in allDestinations) d.id: d};

    final List<LatLng> routePoints = [];
    final Set<Marker> markers = {};

    for (var i = 0; i < widget.journey.stops.length; i++) {
      final stop = widget.journey.stops[i];
      final Destination? destination = destinationMap[stop.destinationId];
      if (destination == null) continue;

      final point = LatLng(destination.latitude, destination.longitude);
      routePoints.add(point);

      markers.add(
        Marker(
          markerId: MarkerId(destination.id),
          position: point,
          infoWindow: InfoWindow(title: '${i + 1}. ${destination.name}', snippet: stop.suggestedTime),
        ),
      );
    }

    setState(() {
      _markers.addAll(markers);
      if (routePoints.length > 1) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('journey_route'),
            points: routePoints,
            color: AppColors.deepTeal,
            width: 4,
          ),
        );
      }
      _isLoading = false;
    });

    if (routePoints.isNotEmpty && _mapController != null) {
      _fitBounds(routePoints);
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
        60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journey Map')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(31.9, 35.9), // roughly central Jordan
          zoom: 7,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) {
          _mapController = controller;
          if (_markers.isNotEmpty) {
            final points = _markers.map((m) => m.position).toList();
            _fitBounds(points);
          }
        },
      ),
    );
  }
}