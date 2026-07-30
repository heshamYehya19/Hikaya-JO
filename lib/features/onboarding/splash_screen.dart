import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/services/app_prefs_service.dart';
import '../../core/services/profile_setup_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      // First launch ever (no language picked yet) — that comes before
      // anything else, even for a returning logged-in user on a fresh install.
      if (!AppPrefsService().hasPickedLanguage) {
        context.goNamed('languageSelect');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final route = await ProfileSetupService().resolvePostAuthRoute();
        context.goNamed(route);
      } else {
        context.goNamed('onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.85 + (value * 0.15), child: child),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 160),
              const SizedBox(height: 16),
              Text('Hikaya JO', style: AppTypography.headline1.copyWith(color: AppColors.deepTeal, fontSize: 30)),
              const SizedBox(height: 8),
              const Text('Your story of Jordan', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}