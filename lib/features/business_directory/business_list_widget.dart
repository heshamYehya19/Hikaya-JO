import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/services/business_service.dart';
import '../../models/business.dart';
import 'business_detail_screen.dart';

class BusinessListWidget extends StatefulWidget {
  final String destinationId;
  const BusinessListWidget({super.key, required this.destinationId});

  @override
  State<BusinessListWidget> createState() => _BusinessListWidgetState();
}

class _BusinessListWidgetState extends State<BusinessListWidget> {
  List<Business> _businesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final businesses = await BusinessService().fetchBusinessesForDestination(widget.destinationId);
    if (mounted) setState(() {
      _businesses = businesses;
      _isLoading = false;
    });
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'guide':
        return Icons.person_pin_circle_outlined;
      case 'artisan':
        return Icons.palette_outlined;
      default:
        return Icons.storefront_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    if (_businesses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.storefront_outlined, color: AppColors.duneGold),
            const SizedBox(width: 8),
            Text('Nearby Businesses', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),
        ...(_businesses.map((biz) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: biz)),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.duneLight),
              ),
              child: Row(
                children: [
                  Icon(_iconForType(biz.type), color: AppColors.deepTeal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(biz.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(biz.offer, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.monetization_on_outlined, size: 14, color: AppColors.duneGold),
                      Text(' ${biz.coinsRequired}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ))),
      ],
    );
  }
}