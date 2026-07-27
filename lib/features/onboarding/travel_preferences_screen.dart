import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class TravelPreferencesScreen extends StatefulWidget {
  const TravelPreferencesScreen({super.key});

  @override
  State<TravelPreferencesScreen> createState() => _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState extends State<TravelPreferencesScreen> {
  String? _budget; // 'low' | 'medium' | 'high' | null
  String? _transport; // 'walking' | 'car' | 'public' | null
  bool _isSaving = false;

  static const Map<String, String> _budgetLabels = {'low': '\$', 'medium': '\$\$', 'high': '\$\$\$'};
  static const Map<String, IconData> _transportIcons = {
    'walking': Icons.directions_walk_outlined,
    'car': Icons.directions_car_outlined,
    'public': Icons.directions_bus_outlined,
  };
  static const Map<String, String> _transportLabels = {'walking': 'Walking', 'car': 'Car', 'public': 'Bus'};

  Future<void> _finish({required bool save}) async {
    setState(() => _isSaving = true);
    if (save) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'budgetLevel': _budget,
          'transportMode': _transport,
        });
      }
    }
    if (mounted) context.goNamed('home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Almost there!', style: AppTypography.headline1.copyWith(fontSize: 26)),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 32),
                child: Text(
                  'Set a default budget and way of getting around — optional, you can skip this',
                  style: AppTypography.bodySecondary,
                ),
              ),
              const Text('Budget', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: ['low', 'medium', 'high'].map((level) {
                  final selected = _budget == level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _budget = selected ? null : level),
                      child: Container(
                        margin: EdgeInsets.only(right: level != 'high' ? 10 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.deepTeal : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? AppColors.deepTeal : AppColors.duneLight),
                        ),
                        child: Text(
                          _budgetLabels[level]!,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: selected ? AppColors.background : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              const Text('Transport', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: ['walking', 'car', 'public'].map((mode) {
                  final selected = _transport == mode;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _transport = selected ? null : mode),
                      child: Container(
                        margin: EdgeInsets.only(right: mode != 'public' ? 10 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.deepTeal.withOpacity(0.15) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? AppColors.deepTeal : AppColors.duneLight, width: selected ? 1.5 : 1),
                        ),
                        child: Column(
                          children: [
                            Icon(_transportIcons[mode], color: selected ? AppColors.deepTeal : AppColors.textSecondary),
                            const SizedBox(height: 6),
                            Text(
                              _transportLabels[mode]!,
                              style: TextStyle(fontSize: 12, color: selected ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _finish(save: true),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : () => _finish(save: false),
                  child: const Text('Skip for now', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}