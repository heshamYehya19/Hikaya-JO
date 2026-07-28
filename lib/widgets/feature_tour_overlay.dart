import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';

class TourStep {
  final IconData icon;
  final String title;
  final String description;
  const TourStep({required this.icon, required this.title, required this.description});
}

/// Full-screen dark overlay with one coach-mark card at a time, positioned
/// above the bottom-nav icon it describes (index-based, assumes an evenly
/// split BottomNavigationBar — matches MainShell's 5 fixed tabs). Tapping
/// anywhere advances to the next step; tapping the last step dismisses.
class FeatureTourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onFinished;
  const FeatureTourOverlay({super.key, required this.steps, required this.onFinished});

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay> with SingleTickerProviderStateMixin {
  int _step = 0;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _advance() {
    if (_step < widget.steps.length - 1) {
      setState(() => _step++);
    } else {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabCount = widget.steps.length;
    final tabCenterX = screenWidth * (_step + 0.5) / tabCount;
    final step = widget.steps[_step];

    const cardWidth = 240.0;
    double cardLeft = tabCenterX - cardWidth / 2;
    cardLeft = cardLeft.clamp(16.0, screenWidth - cardWidth - 16.0);
    final arrowLeft = (tabCenterX - cardLeft - 10).clamp(16.0, cardWidth - 26.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(_step),
          color: Colors.black.withOpacity(0.55),
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Positioned(
                left: cardLeft,
                bottom: 38,
                width: cardWidth,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.deepTeal.withOpacity(0.5)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(step.icon, color: AppColors.deepTeal, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(step.title, style: AppTypography.headline2.copyWith(fontSize: 15))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(step.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_step + 1}/${widget.steps.length}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                Text(
                                  _step < widget.steps.length - 1 ? 'Tap to continue' : 'Tap to finish',
                                  style: const TextStyle(color: AppColors.deepTeal, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: arrowLeft),
                        child: AnimatedBuilder(
                          animation: _bounceController,
                          builder: (context, child) => Transform.translate(offset: Offset(0, _bounceController.value * 6), child: child),
                          child: const Icon(Icons.arrow_drop_down, color: AppColors.deepTeal, size: 34),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}