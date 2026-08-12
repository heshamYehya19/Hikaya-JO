import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/router/page_transitions.dart';
import '../../core/services/journey_service.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';
import '../../providers/journey_provider.dart';
import 'itinerary_screen.dart';

class JourneyRouteScreen extends ConsumerStatefulWidget {
  final Journey journey;
  const JourneyRouteScreen({super.key, required this.journey});

  @override
  ConsumerState<JourneyRouteScreen> createState() => _JourneyRouteScreenState();
}

class _JourneyRouteScreenState extends ConsumerState<JourneyRouteScreen> {
  Map<String, Destination> _destinationMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final all = await JourneyService().fetchAllDestinations();
    if (!mounted) return;
    setState(() {
      _destinationMap = {for (var d in all) d.id: d};
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    final visitedAsync = ref.watch(userVisitedLocationsProvider);
    final visited = visitedAsync.valueOrNull ?? const <String>[];
    final firstDestination = journey.stops.isNotEmpty ? _destinationMap[journey.stops.first.destinationId] : null;
    final hasHeroImage = firstDestination?.imageAt(4) != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasHeroImage)
            Opacity(
              opacity: 0.35,
              child: CachedNetworkImage(imageUrl: firstDestination!.imageAt(4)!, fit: BoxFit.cover),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background.withOpacity(0.4), AppColors.background.withOpacity(0.97)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Route', style: AppTypography.headline2.copyWith(fontSize: 20)),
                            const Text('Tap a stop to see it come alive', style: AppTypography.bodySecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _MiniStat(value: '${journey.stops.length}', label: 'Stops'),
                      const SizedBox(width: 16),
                      _MiniStat(value: (journey.totalDurationMinutes / 60).toStringAsFixed(1), label: 'Hours'),
                      const SizedBox(width: 16),
                      _MiniStat(value: journey.totalCost.toStringAsFixed(0), label: 'JOD'),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.deepTeal))
                      : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Column(
                      children: List.generate(journey.stops.length, (index) {
                        final stop = journey.stops[index];
                        final isLast = index == journey.stops.length - 1;
                        final isVisited = visited.contains(stop.destinationId);
                        return _RouteNode(
                          index: index,
                          stopName: stop.destinationName,
                          stopTime: stop.suggestedTime,
                          isLeft: index.isEven,
                          isLast: isLast,
                          isVisited: isVisited,
                          animationDelay: Duration(milliseconds: 150 * index),
                        );
                      }),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        smoothPageRoute(const ItineraryScreen()),
                      ),
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text('View Full Itinerary'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.duneLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(color: AppColors.duneGold, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}

/// One stop on the winding route: a numbered (or checkmarked, if already
/// visited) circle on a central dashed line, with its name/time label
/// alternating left and right for a zigzag "path" feel. Pops in with a
/// staggered fade+slide, and gives a little tap-bounce for interactivity.
class _RouteNode extends StatefulWidget {
  final int index;
  final String stopName;
  final String stopTime;
  final bool isLeft;
  final bool isLast;
  final bool isVisited;
  final Duration animationDelay;

  const _RouteNode({
    required this.index,
    required this.stopName,
    required this.stopTime,
    required this.isLeft,
    required this.isLast,
    required this.isVisited,
    required this.animationDelay,
  });

  @override
  State<_RouteNode> createState() => _RouteNodeState();
}

class _RouteNodeState extends State<_RouteNode> {
  bool _tapped = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.animationDelay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    setState(() => _tapped = true);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _tapped = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final circleColor = widget.isVisited ? AppColors.teal : AppColors.deepTeal;

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : Offset(widget.isLeft ? -0.08 : 0.08, 0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          height: 92,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: widget.isLeft ? _label(alignEnd: true) : const SizedBox.shrink()),
              Column(
                children: [
                  GestureDetector(
                    onTap: _onTap,
                    child: AnimatedScale(
                      scale: _tapped ? 1.18 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: circleColor.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)],
                        ),
                        child: widget.isVisited
                            ? const Icon(Icons.check, color: AppColors.background, size: 20)
                            : Text(
                          '${widget.index + 1}',
                          style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isLast)
                    Expanded(child: CustomPaint(size: const Size(2, double.infinity), painter: _DashedLinePainter())),
                ],
              ),
              Expanded(child: !widget.isLeft ? _label(alignEnd: false) : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label({required bool alignEnd}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            widget.stopName,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(widget.stopTime, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.duneLight
      ..strokeWidth = 2;
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}