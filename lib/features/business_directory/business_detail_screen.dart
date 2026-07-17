import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/services/business_service.dart';
import '../../models/business.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Business business;
  const BusinessDetailScreen({super.key, required this.business});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  bool _isRedeeming = false;
  String? _resultMessage;
  bool _success = false;

  Future<void> _redeem() async {
    setState(() => _isRedeeming = true);
    final error = await BusinessService().redeemOffer(widget.business);
    setState(() {
      _isRedeeming = false;
      _success = error == null;
      _resultMessage = error ?? '✅ Offer redeemed! Show this screen at ${widget.business.name}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final biz = widget.business;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(biz.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(biz.type.toUpperCase(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(biz.name, style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.deepTeal)),
              const SizedBox(height: 16),
              Text(biz.description, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.duneGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.duneGold.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(biz.offer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Costs ${biz.coinsRequired} coins', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_resultMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (_success ? AppColors.teal : AppColors.error).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_resultMessage!, style: TextStyle(color: _success ? AppColors.teal : AppColors.error)),
                ),
              const SizedBox(height: 12),
              if (!_success)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRedeeming ? null : _redeem,
                    child: _isRedeeming
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                        : const Text('Redeem with Coins'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}