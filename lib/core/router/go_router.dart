import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import 'page_transitions.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/hikaya_talk/hikaya_talk_screen.dart';
import '../../features/hikaya_hunt/geofence_test_screen.dart';
import '../../features/home/main_shell.dart';
import '../../features/journey_planner/seed_screen.dart';
import '../../core/services/challenge_seed_service.dart';
import '../../features/onboarding/interests_setup_screen.dart';
import '../../features/onboarding/travel_preferences_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/interests-setup',
      name: 'interestsSetup',
      pageBuilder: (context, state) => smoothPage(key: state.pageKey, child: const InterestsSetupScreen()),
    ),
    GoRoute(
      path: '/travel-preferences',
      name: 'travelPreferences',
      pageBuilder: (context, state) => smoothPage(key: state.pageKey, child: const TravelPreferencesScreen()),
    ),
    GoRoute(
      path: '/talk',
      name: 'hikayaTalk',
      pageBuilder: (context, state) => smoothPage(key: state.pageKey, child: const HikayaTalkScreen()),
    ),
    GoRoute(
      path: '/',
      name: 'splash',
      pageBuilder: (context, state) => smoothPage(key: state.pageKey, child: const SplashScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => smoothPage(key: state.pageKey, child: const OnboardingScreen()),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => smoothPage(key: state.pageKey, child: const LoginScreen()),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      pageBuilder: (context, state) => smoothPage(key: state.pageKey, child: const SignUpScreen()),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (context, state) => smoothPage(key: state.pageKey, child: const MainShell()),
    ),
    // Dev-only utility screens — writes/overwrites Firestore data or bypass
    // location checks, so these must never be reachable in a release build
    // (a route is just a URL on Flutter Web, so "no button links here" isn't
    // enough gating on its own).
    if (kDebugMode) ...[
      GoRoute(
        path: '/seed',
        name: 'seed',
        builder: (context, state) => const SeedScreen(),
      ),
      GoRoute(
        path: '/geofence-test',
        name: 'geofenceTest',
        builder: (context, state) => const GeofenceTestScreen(),
      ),
    ],
  ],
);