import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/localization/app_locale.dart';
import '../../providers/main_tab_provider.dart';
import 'home_screen.dart';
import '../journey_planner/journey_planner_input_screen.dart';
import '../hikaya_hunt/challenge_list_screen.dart';
import '../hikaya_talk/hikaya_talk_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/offline_banner.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    JourneyPlannerInputScreen(),
    ChallengeListScreen(),
    HikayaTalkScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabIndexProvider);
    final t = AppLocale.of(context).t;

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: IndexedStack(index: currentIndex, children: _screens)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(mainTabIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.deepTeal,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: t('nav_home')),
          BottomNavigationBarItem(icon: const Icon(Icons.map_outlined), label: t('nav_journey')),
          BottomNavigationBarItem(icon: const Icon(Icons.emoji_events_outlined), label: t('nav_hunt')),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), label: t('nav_talk')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: t('nav_profile')),
        ],
      ),
    );
  }
}