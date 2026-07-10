import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/hikaya_hunt/geofence_test_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/geofence-test', // TEMP — change back after testing
  routes: [
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
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Home Dashboard — coming in Week 3')),
      ),
    ),
    GoRoute(
      path: '/geofence-test',
      name: 'geofenceTest',
      builder: (context, state) => const GeofenceTestScreen(),
    ),
  ],
);