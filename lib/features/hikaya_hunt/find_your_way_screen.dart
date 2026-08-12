import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/router/page_transitions.dart';
import '../../core/services/location_service.dart';
import '../../models/challenge.dart';
import 'camera_capture_screen.dart';

/// Live compass pointing at a challenge's exact coordinates — not just the
/// destination broadly. Distance/geofence already tells you "you're close",
/// this tells you which direction to actually walk for the last stretch.
class FindYourWayScreen extends StatefulWidget {
  final Challenge challenge;
  const FindYourWayScreen({super.key, required this.challenge});

  @override
  State<FindYourWayScreen> createState() => _FindYourWayScreenState();
}

class _FindYourWayScreenState extends State<FindYourWayScreen> with SingleTickerProviderStateMixin {
  final _locationService = LocationService();
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _hapticTimer;

  late final AnimationController _sweepController;

  double? _heading;
  double? _bearingToTarget;
  double? _distanceMeters;
  bool _compassAvailable = true;
  bool _isWithinRange = false;
  int _celebrationTrigger = 0;

  static const double _referenceDistance = 400; // beyond this, no hot/cold feedback

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _startCompass();
    _startLocation();
  }

  void _startCompass() {
    if (FlutterCompass.events == null) {
      setState(() => _compassAvailable = false);
      return;
    }
    _compassSub = FlutterCompass.events!.listen((event) {
      if (event.heading != null && mounted) {
        setState(() => _heading = event.heading);
      }
    });
  }

  Future<void> _startLocation() async {
    final hasPermission = await _locationService.ensureLocationPermission();
    if (!hasPermission) return;

    _positionSub = _locationService.watchPosition().listen((position) {
      if (!mounted) return;
      final bearing = Geolocator.bearingBetween(
        position.latitude,
        position.longitude,
        widget.challenge.latitude,
        widget.challenge.longitude,
      );
      final distance = _locationService.distanceToTarget(
        userLat: position.latitude,
        userLng: position.longitude,
        targetLat: widget.challenge.latitude,
        targetLng: widget.challenge.longitude,
      );
      final wasWithinRange = _isWithinRange;
      final nowWithinRange = distance <= widget.challenge.radiusMeters;

      setState(() {
        _bearingToTarget = bearing < 0 ? bearing + 360 : bearing;
        _distanceMeters = distance;
        _isWithinRange = nowWithinRange;
      });

      if (!wasWithinRange && nowWithinRange) {
        HapticFeedback.heavyImpact();
        setState(() => _celebrationTrigger++);
        _hapticTimer?.cancel();
      } else if (!nowWithinRange) {
        _scheduleNextHaptic(distance);
      }
    });
  }

  void _scheduleNextHaptic(double distance) {
    _hapticTimer?.cancel();
    if (distance > _referenceDistance) return;

    // Closer = faster ticks — a "getting warmer" Geiger-counter feel.
    final closeness = 1 - (distance / _referenceDistance).clamp(0.0, 1.0);
    final intervalMs = (1200 - (closeness * 1000)).clamp(180, 1200).round();

    _hapticTimer = Timer(Duration(milliseconds: intervalMs), () {
      if (!mounted || _isWithinRange) return;
      HapticFeedback.lightImpact();
      if (_distanceMeters != null) _scheduleNextHaptic(_distanceMeters!);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _compassSub?.cancel();
    _hapticTimer?.cancel();
    _sweepController.dispose();
    super.dispose();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  Color _proximityColor(double? distance) {
    if (distance == null) return AppColors.duneLight;
    final closeness = 1 - (distance / _referenceDistance).clamp(0.0, 1.0);
    return Color.lerp(AppColors.duneLight, AppColors.duneGold, closeness) ?? AppColors.duneLight;
  }

  @override
  Widget build(BuildContext context) {
    final arrowAngle = (_heading != null && _bearingToTarget != null)
        ? ((_bearingToTarget! - _heading!) * math.pi / 180)
        : null;
    final ringColor = _isWithinRange ? AppColors.teal : _proximityColor(_distanceMeters);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Find Your Way', style: AppTypography.headline1.copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                widget.challenge.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const Spacer(),
              if (!_compassAvailable)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "This device doesn't have a compass sensor — use the distance below and your map instead.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient radar sweep — purely atmospheric.
                      AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, child) => Transform.rotate(
                          angle: _sweepController.value * 2 * math.pi,
                          child: child,
                        ),
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                ringColor.withOpacity(0.0),
                                ringColor.withOpacity(0.12),
                                ringColor.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.08, 0.16],
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: ringColor, width: 2.5),
                          boxShadow: [BoxShadow(color: ringColor.withOpacity(0.3), blurRadius: 16, spreadRadius: 1)],
                        ),
                      ),
                      _SmoothNeedle(targetAngle: arrowAngle, color: ringColor),
                      // "Found It!" burst — fires once per range-entry via the key.
                      if (_isWithinRange)
                        TweenAnimationBuilder<double>(
                          key: ValueKey(_celebrationTrigger),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOut,
                          builder: (context, value, child) => Opacity(
                            opacity: (1 - value).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 1 + value * 0.8,
                              child: Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.teal, width: 3)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              if (_distanceMeters != null)
                _isWithinRange
                    ? const Text("You're here! 🎉", style: TextStyle(color: AppColors.teal, fontSize: 22, fontWeight: FontWeight.bold))
                    : AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  style: TextStyle(color: _proximityColor(_distanceMeters), fontSize: 20, fontWeight: FontWeight.bold),
                  child: Text('${_formatDistance(_distanceMeters!)} away'),
                )
              else
                const Text('Locating…', style: TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              if (_isWithinRange)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      smoothPageRoute(CameraCaptureScreen(challenge: widget.challenge)),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take Photo & Unlock'),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compass needle that swings and settles toward a new angle instead of
/// snapping instantly — always takes the shortest rotational path, so it
/// never spins the "long way around" when crossing north.
class _SmoothNeedle extends StatefulWidget {
  final double? targetAngle;
  final Color color;
  const _SmoothNeedle({required this.targetAngle, required this.color});

  @override
  State<_SmoothNeedle> createState() => _SmoothNeedleState();
}

class _SmoothNeedleState extends State<_SmoothNeedle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double> _animation = const AlwaysStoppedAnimation(0);
  double _displayedAngle = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  double _shortestPath(double from, double to) {
    double delta = (to - from) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    return from + delta;
  }

  @override
  void didUpdateWidget(covariant _SmoothNeedle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeAnimateTo(widget.targetAngle);
  }

  void _maybeAnimateTo(double? target) {
    if (target == null) return;
    if (!_initialized) {
      _initialized = true;
      _displayedAngle = target;
      return;
    }
    final endAngle = _shortestPath(_displayedAngle, target);
    _animation = Tween<double>(begin: _displayedAngle, end: endAngle)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic))
      ..addListener(() => setState(() => _displayedAngle = _animation.value));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized && widget.targetAngle != null) {
      _initialized = true;
      _displayedAngle = widget.targetAngle!;
    }
    return Transform.rotate(
      angle: _displayedAngle,
      child: Icon(Icons.navigation_rounded, size: 90, color: widget.color),
    );
  }
}