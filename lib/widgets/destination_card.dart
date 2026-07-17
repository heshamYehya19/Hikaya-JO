import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../models/destination.dart';

/// Photo card used in horizontal destination lists (Home's "Popular
/// Destinations", journey results, etc). Falls back to a gradient + type
/// icon when a destination has no imageUrls — your current /seed data
/// doesn't populate images yet, so this fallback is the common case for now.
class DestinationCard extends StatelessWidget {
  const DestinationCard({
    super.key,
    required this.destination,
    this.onTap,
    this.width = 150,
    this.height = 160,
  });

  final Destination destination;
  final VoidCallback? onTap;
  final double width;
  final double height;

  IconData get _typeIcon {
    switch (destination.type) {
      case 'natural':
        return Icons.landscape_outlined;
      case 'cultural':
        return Icons.temple_buddhist_outlined;
      case 'historical':
      default:
        return Icons.account_balance_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = destination.imageUrls.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              hasImage
                  ? Image.network(
                      destination.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.background.withOpacity(0.9)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination.type,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.background],
        ),
      ),
      child: Center(child: Icon(_typeIcon, size: 36, color: AppColors.duneGold)),
    );
  }
}
