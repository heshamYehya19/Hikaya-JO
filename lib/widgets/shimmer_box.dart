import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// A skeleton-loading placeholder — a rounded box with a soft light band
/// sweeping across it on a loop. Used in place of a bare centered spinner
/// for list-shaped content (destination carousels, challenge lists), so the
/// loading state hints at the shape of what's coming instead of just
/// blocking the screen.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  const ShimmerBox({super.key, this.width, required this.height, this.borderRadius = const BorderRadius.all(Radius.circular(14))});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                final t = _controller.value;
                return LinearGradient(
                  begin: Alignment(-1.5 + 3 * t, 0),
                  end: Alignment(-0.5 + 3 * t, 0),
                  colors: [AppColors.surfaceElevated, AppColors.duneLight, AppColors.surfaceElevated],
                ).createShader(bounds);
              },
              child: Container(color: AppColors.surfaceElevated),
            );
          },
        ),
      ),
    );
  }
}

/// A row of ShimmerBox cards shaped like DestinationCard/challenge-card
/// content — drop-in replacement for a centered CircularProgressIndicator
/// wherever a horizontal or vertical list is loading.
class ShimmerCardRow extends StatelessWidget {
  final int count;
  final double cardWidth;
  final double cardHeight;
  const ShimmerCardRow({super.key, this.count = 4, this.cardWidth = 150, this.cardHeight = 160});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => ShimmerBox(width: cardWidth, height: cardHeight, borderRadius: BorderRadius.circular(18)),
    );
  }
}
