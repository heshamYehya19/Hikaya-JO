import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class _InterestOption {
  final String label;
  final IconData icon;
  const _InterestOption(this.label, this.icon);
}

class InterestsSetupScreen extends StatefulWidget {
  const InterestsSetupScreen({super.key});

  @override
  State<InterestsSetupScreen> createState() => _InterestsSetupScreenState();
}

class _InterestsSetupScreenState extends State<InterestsSetupScreen> {
  static const List<_InterestOption> _allInterests = [
    _InterestOption('History', Icons.account_balance_outlined),
    _InterestOption('Nature', Icons.park_outlined),
    _InterestOption('Culture', Icons.theater_comedy_outlined),
    _InterestOption('Adventure', Icons.hiking_outlined),
    _InterestOption('Food', Icons.restaurant_outlined),
    _InterestOption('Photography', Icons.camera_alt_outlined),
  ];

  final Set<String> _selected = {};
  bool _isSaving = false;

  Future<void> _continue() async {
    if (_selected.isEmpty) return; // safety net — button is disabled anyway

    setState(() => _isSaving = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'interests': _selected.toList(),
      });
    }
    if (mounted) context.goNamed('travelPreferences');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // not skippable — hardware back can't escape this screen either
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What are you interested in?', style: AppTypography.headline1.copyWith(fontSize: 26)),
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 32),
                  child: Text(
                    "We'll use this to personalize what you see — pick at least one to continue",
                    style: AppTypography.bodySecondary,
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                    children: _allInterests.map((option) {
                      final selected = _selected.contains(option.label);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected ? _selected.remove(option.label) : _selected.add(option.label);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.deepTeal.withOpacity(0.15) : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: selected ? AppColors.deepTeal : AppColors.duneLight, width: selected ? 1.5 : 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(option.icon, color: selected ? AppColors.deepTeal : AppColors.textSecondary, size: 26),
                              const SizedBox(height: 8),
                              Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selected.isEmpty || _isSaving) ? null : _continue,
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                        : const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}