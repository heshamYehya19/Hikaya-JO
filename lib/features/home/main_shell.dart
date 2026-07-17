import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Journey'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Hunt'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Talk'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
