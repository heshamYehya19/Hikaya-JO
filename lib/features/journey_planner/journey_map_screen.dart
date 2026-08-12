import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/colors.dart';
import '../../core/services/journey_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/directions_service.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/journey_provider.dart';

class JourneyMapScreen extends ConsumerStatefulWidget {
  final Journey journey;
  const JourneyMapScreen({super.key, required this.journey});

  @override
  ConsumerState<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends ConsumerState<JourneyMapScreen> {
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#17171a"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0d0d0f"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#a3a0a0"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#2e2e33"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#1f1f23"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#a3a0a0"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1a2620"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2a2a2e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#17171a"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8785"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3a3530"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#d4a857"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#1f1f23"}]},
  {"featureType": "transit.station", "elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
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

  bool _optimisticStart = false;

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

    await _buildMarkers();
    _buildOverviewPath();

    setState(() => _isLoading = false);

    // onMapCreated only fits bounds if markers are already populated by the
    // time the native map view finishes attaching. If the controller
    // becomes available before this point instead (e.g. the platform view
    // was already created from a previous build), that fit never happens
    // and the camera is stuck on initialCameraPosition. Covering both
    // orderings here rather than assuming markers always win the race.
    if (_mapController != null && _markers.isNotEmpty) {
      _fitBounds(_markers.map((m) => m.position).toList());
    }
  }

  Future<BitmapDescriptor> _numberedMarkerIcon(int number) async {
    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final borderPaint = Paint()..color = const Color(0xFF0D0D0F);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, borderPaint);

    final fillPaint = Paint()..color = const Color(0xFFD4A857);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 5, fillPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0D0D0F)),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _buildMarkers() async {
    final Set<Marker> markers = {};

    for (var i = 0; i < widget.journey.stops.length; i++) {
      final stop = widget.journey.stops[i];
      final destination = _destinationMap[stop.destinationId];
      if (destination == null) continue;

      final icon = await _numberedMarkerIcon(i + 1);

      markers.add(
        Marker(
          markerId: MarkerId(destination.id),
          position: LatLng(destination.latitude, destination.longitude),
          icon: icon,
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

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  void _buildOverviewPath() {
    final points = <LatLng>[];
    for (final stop in widget.journey.stops) {
      final d = _destinationMap[stop.destinationId];
      if (d != null) points.add(LatLng(d.latitude, d.longitude));
    }
    if (points.length < 2) return;

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('journey_overview'),
        points: points,
        color: AppColors.deepTeal.withOpacity(0.55),
        width: 3,
        patterns: [PatternItem.dash(14), PatternItem.gap(10)],
      ),
    );
  }

  Future<void> _selectStop(String destinationId, String destinationName, {bool animateCamera = true}) async {
    final destination = _destinationMap[destinationId];
    if (destination == null) return;

    setState(() {
      _selectedStopName = destinationName;
      _polylines.removeWhere((p) => p.polylineId.value == 'user_to_selected');
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
                // A camera command issued the instant the controller
                // attaches can get dropped before the native view has
                // finished laying out its surface — deferring one frame
                // gives it a real size to fit bounds against.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _fitBounds(_markers.map((m) => m.position).toList());
                });
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
                    child: _isJourneyStarted
                        ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.teal),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _LiveDot(),
                          const SizedBox(width: 10),
                          Text(
                            widget.journey.startedAt != null
                                ? 'In Progress · Started ${_formatStartTime(widget.journey.startedAt!)}'
                                : 'Journey in Progress',
                            style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                        : _PulsingStartButton(
                      enabled: widget.journey.stops.isNotEmpty,
                      onTap: () async {
                        final first = widget.journey.stops.first;
                        _selectStop(first.destinationId, first.destinationName);
                        setState(() => _optimisticStart = true);
                        await JourneyService().markJourneyStarted(widget.journey.id);
                        ref.invalidate(latestJourneyProvider);
                        ref.invalidate(userJourneysProvider);
                      },
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
  bool get _isJourneyStarted => _optimisticStart || widget.journey.startedAt != null;

  String _formatStartTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// A "live" pulsing dot — solid center dot with an expanding, fading ring —
/// used anywhere something is genuinely happening in real time right now.
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - _controller.value).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1 + (_controller.value * 1.4),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The "Start Journey" button itself, with a gentle breathing glow to
/// invite the tap — same pulsing language used on the arrival reveal's CTA.
class _PulsingStartButton extends StatefulWidget {
  final bool enabled;
  final Future<void> Function() onTap;
  const _PulsingStartButton({required this.enabled, required this.onTap});

  @override
  State<_PulsingStartButton> createState() => _PulsingStartButtonState();
}

class _PulsingStartButtonState extends State<_PulsingStartButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    setState(() => _isStarting = true);
    await widget.onTap();
    if (mounted) setState(() => _isStarting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: widget.enabled
              ? [BoxShadow(color: AppColors.deepTeal.withOpacity(0.25 + _controller.value * 0.2), blurRadius: 14, spreadRadius: 1)]
              : null,
        ),
        child: child,
      ),
      child: ElevatedButton(
        onPressed: (!widget.enabled || _isStarting) ? null : _handleTap,
        child: _isStarting
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
            : const Text('Start Journey'),
      ),
    );
  }
}