import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/hikaya_talk/hikaya_talk_screen.dart';
import '../../features/hikaya_hunt/geofence_test_screen.dart';
import '../../features/home/main_shell.dart';
import '../../features/journey_planner/seed_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/talk',
      name: 'hikayaTalk',
      builder: (context, state) => const HikayaTalkScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const MainShell(),
    ),
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
);