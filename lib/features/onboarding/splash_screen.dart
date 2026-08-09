import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/services/profile_setup_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/splash_logo.mp4')
      ..setLooping(false)
      ..setVolume(0) // silent — splash videos shouldn't play audio
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {}); // rebuild once the first frame is ready to show
        _controller.play();
      });

    // Navigate exactly when the video actually finishes, rather than
    // guessing a fixed delay that could cut the animation off early or
    // leave an awkward pause after it ends.
    _controller.addListener(_checkVideoFinished);
  }

  void _checkVideoFinished() {
    if (_hasNavigated) return;
    final value = _controller.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _hasNavigated = true;
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;


    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final route = await ProfileSetupService().resolvePostAuthRoute();
      if (mounted) context.goNamed(route);
    } else {
      context.goNamed('onboarding');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoFinished);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: _controller.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : const SizedBox(height: 160), // reserves space so nothing jumps once the video loads
            ),
            const SizedBox(height: 16),
            Text('Hikaya JO', style: AppTypography.headline1.copyWith(color: AppColors.deepTeal, fontSize: 30)),
            const SizedBox(height: 8),
            const Text('Every Place Has A Story', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}