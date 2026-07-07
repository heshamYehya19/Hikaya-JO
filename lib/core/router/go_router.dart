import 'package:go_router/go_router.dart';
import '../../features/onboarding/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    // next routes added as we build: '/onboarding', '/login', '/home' ...
  ],
);