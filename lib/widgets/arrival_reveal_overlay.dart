import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../models/destination.dart';

/// Full-screen "you've arrived" reveal shown when ArrivalWatcherService
/// detects the user has entered a journey stop's radius. The CTA opens
/// Story Mode; tapping anywhere else dismisses without listening.
class ArrivalRevealOverlay extends StatelessWidget {
  final Destination destination;
  final VoidCallback onDismiss;
  final VoidCallback onListen;

  const ArrivalRevealOverlay({super.key, required this.destination, required this.onDismiss, required this.onListen});

  @override
  Widget build(BuildContext context) {
    final hasImage = destination.imageAt(0) != null;

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage) Image.network(destination.imageAt(0)!, fit: BoxFit.cover) else Container(color: AppColors.background),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background.withOpacity(0.75), AppColors.background.withOpacity(0.95)],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: AppColors.deepTeal, shape: BoxShape.circle),
                      child: const Icon(Icons.location_on, color: AppColors.background, size: 34),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("You've Arrived!", textAlign: TextAlign.center, style: AppTypography.headline1.copyWith(fontSize: 26)),
                  const SizedBox(height: 8),
                  Text(
                    destination.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.duneGold, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),
                  _PulsingButton(onTap: onListen),
                  const SizedBox(height: 20),
                  Text('Tap anywhere else to dismiss', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PulsingButton({required this.onTap});

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(scale: 1.0 + (_controller.value * 0.04), child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.deepTeal,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: AppColors.deepTeal.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.headphones_rounded, color: AppColors.background),
              const SizedBox(width: 10),
              const Text('Listen to the Story', style: TextStyle(color: AppColors.background, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}