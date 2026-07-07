import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 160),
            const SizedBox(height: 16),
            Text(
              'Hikaya JO',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.deepTeal),
            ),
            const SizedBox(height: 8),
            Text('Your story of Jordan', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}