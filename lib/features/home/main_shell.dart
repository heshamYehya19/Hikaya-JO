import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'home_screen.dart';
import '../journey_planner/journey_planner_input_screen.dart';
import '../hikaya_hunt/challenge_list_screen.dart';
import '../hikaya_talk/hikaya_talk_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    JourneyPlannerInputScreen(),
    const ChallengeListScreen(),
    HikayaTalkScreen(),
    Center(child: Text('Profile — coming soon')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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