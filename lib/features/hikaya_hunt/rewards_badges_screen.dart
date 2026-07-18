import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class RewardsBadgesScreen extends StatelessWidget {
  const RewardsBadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Text('My Rewards', style: AppTypography.headline2.copyWith(fontSize: 20)),
                ],
              ),
            ),
            Expanded(
              child: userId == null
                  ? const Center(child: Text('Not logged in', style: TextStyle(color: AppColors.textSecondary)))
                  : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.deepTeal));
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final coins = data['coins'] ?? 0;
                  final badges = List<String>.from(data['badges'] ?? []);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: AppColors.deepTeal,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.monetization_on_outlined, color: AppColors.background, size: 36),
                              const SizedBox(height: 8),
                              Text('$coins', style: const TextStyle(color: AppColors.background, fontSize: 34, fontWeight: FontWeight.bold)),
                              Text('Coins Earned', style: TextStyle(color: AppColors.background.withOpacity(0.7), fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text('Badges', style: AppTypography.headline2.copyWith(fontSize: 18)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: badges.isEmpty
                              ? Center(
                            child: Text('Complete challenges to earn badges', style: TextStyle(color: AppColors.textSecondary)),
                          )
                              : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.6,
                            ),
                            itemCount: badges.length,
                            itemBuilder: (context, index) => Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.deepTeal.withOpacity(0.3)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.emoji_events, color: AppColors.duneGold, size: 28),
                                  const SizedBox(height: 6),
                                  Text(
                                    badges[index],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}