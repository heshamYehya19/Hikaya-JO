import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marhaba${user?.email != null ? '' : ''} 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.deepTeal),
              ),
              const SizedBox(height: 4),
              Text('Ready to explore Jordan?', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              _QuickActionCard(
                icon: Icons.map_outlined,
                title: 'Plan a Journey',
                subtitle: 'Get a personalized route through Jordan',
                color: AppColors.deepTeal,
              ),
              const SizedBox(height: 16),
              _QuickActionCard(
                icon: Icons.emoji_events_outlined,
                title: 'Hikaya Hunt',
                subtitle: 'Discover challenges nearby',
                color: AppColors.teal,
              ),
              const SizedBox(height: 16),
              _QuickActionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Hikaya Talk',
                subtitle: 'Speak with locals, live',
                color: AppColors.duneGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.duneLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}