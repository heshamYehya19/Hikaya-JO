import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/services/story_guide_service.dart';
import '../../core/services/hunt_service.dart';
import '../../providers/main_tab_provider.dart';
import '../../models/destination.dart';

enum _PlaybackState { idle, loading, playing, paused, finished }

class StoryModeScreen extends ConsumerStatefulWidget {
  final Destination destination;
  const StoryModeScreen({super.key, required this.destination});

  @override
  ConsumerState<StoryModeScreen> createState() => _StoryModeScreenState();
}

class _StoryModeScreenState extends ConsumerState<StoryModeScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final StoryGuideService _storyService = StoryGuideService();
  late final AnimationController _waveController;

  String _story = '';
  int _spokenChars = 0;
  _PlaybackState _state = _PlaybackState.idle;
  bool _bonusAwarded = false;
  int _unlockedChallengeCount = 0;
  bool _showUnlockBanner = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _tts.setProgressHandler((text, start, end, word) {
      if (mounted) setState(() => _spokenChars = end);
    });
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _state = _PlaybackState.finished);
        _awardBonus();
      }
    });
    _loadStory();
  }

  Future<void> _loadStory() async {
    setState(() => _state = _PlaybackState.loading);
    final story = await _storyService.getStory(widget.destination);
    if (!mounted) return;
    setState(() {
      _story = story;
      _state = _PlaybackState.idle;
    });
  }

  Future<void> _play() async {
    setState(() {
      _spokenChars = 0;
      _state = _PlaybackState.playing;
    });
    await _tts.speak(_story);
  }

  Future<void> _pause() async {
    await _tts.pause();
    setState(() => _state = _PlaybackState.paused);
  }

  Future<void> _replay() async {
    await _tts.stop();
    setState(() {
      _spokenChars = 0;
      _bonusAwarded = false;
      _state = _PlaybackState.playing;
    });
    await _tts.speak(_story);
  }

  Future<void> _awardBonus() async {
    final awarded = await _storyService.awardStoryBonus(widget.destination);
    if (!mounted) return;

    if (awarded) {
      setState(() => _bonusAwarded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🪙 +10 Coins — thanks for listening in person!')),
      );
    }

    final allChallenges = await HuntService().fetchChallenges();
    final here = allChallenges.where((c) => c.destinationId == widget.destination.id).length;
    if (!mounted || here == 0) return;

    setState(() {
      _unlockedChallengeCount = here;
      _showUnlockBanner = true;
    });
  }

  void _goToHunt() {
    ref.read(mainTabIndexProvider.notifier).state = 2;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _tts.stop();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.destination.imageAt(1) != null;
    final isPlaying = _state == _PlaybackState.playing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage) Image.network(widget.destination.imageAt(1)!, fit: BoxFit.cover) else Container(color: AppColors.surfaceElevated),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background.withOpacity(0.55), AppColors.background.withOpacity(0.97)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
                      ),
                    ],
                  ),
                ),
                // Scrolls independently — a long story can never push the
                // controls below off-screen or trigger an overflow, it just
                // scrolls within this region instead.
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(widget.destination.name, textAlign: TextAlign.center, style: AppTypography.headline1.copyWith(fontSize: 26)),
                        const SizedBox(height: 20),
                        _state == _PlaybackState.loading
                            ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: AppColors.deepTeal),
                        )
                            : _StoryText(story: _story, spokenChars: _spokenChars),
                        const SizedBox(height: 28),
                        if (isPlaying) _Waveform(animation: _waveController),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // Fixed bottom section — always visible, never pushed
                // off-screen regardless of story length or device height.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: (_state == _PlaybackState.idle || _state == _PlaybackState.loading) ? null : _replay,
                            icon: const Icon(Icons.replay_rounded, color: AppColors.textSecondary, size: 26),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: _state == _PlaybackState.loading ? null : (isPlaying ? _pause : _play),
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.deepTeal,
                                boxShadow: [BoxShadow(color: AppColors.deepTeal.withOpacity(0.35), blurRadius: 20, spreadRadius: 2)],
                              ),
                              child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.background, size: 36),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(width: 26, child: _bonusAwarded ? const Icon(Icons.monetization_on, color: AppColors.duneGold, size: 26) : null),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        switch (_state) {
                          _PlaybackState.idle => 'Tap play to hear the story',
                          _PlaybackState.loading => 'Writing your story…',
                          _PlaybackState.playing => 'Narrating…',
                          _PlaybackState.paused => 'Paused',
                          _PlaybackState.finished => _bonusAwarded ? 'Story complete — enjoy your bonus!' : 'Story complete',
                        },
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      if (_showUnlockBanner) ...[
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) => Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child),
                          ),
                          child: GestureDetector(
                            onTap: _goToHunt,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.duneGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.duneGold),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_open_rounded, color: AppColors.duneGold, size: 26),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$_unlockedChallengeCount Challenge${_unlockedChallengeCount == 1 ? '' : 's'} Unlocked!',
                                          style: const TextStyle(color: AppColors.duneGold, fontWeight: FontWeight.w700, fontSize: 15),
                                        ),
                                        const Text('Tap to go hunt them down', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.duneGold, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryText extends StatelessWidget {
  final String story;
  final int spokenChars;
  const _StoryText({required this.story, required this.spokenChars});

  @override
  Widget build(BuildContext context) {
    if (story.isEmpty) return const SizedBox.shrink();
    final clamped = spokenChars.clamp(0, story.length);
    final spoken = story.substring(0, clamped);
    final rest = story.substring(clamped);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: spoken, style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, height: 1.5, fontWeight: FontWeight.w500)),
          TextSpan(text: rest, style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 17, height: 1.5)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _Waveform extends StatelessWidget {
  final Animation<double> animation;
  const _Waveform({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(24, (i) {
              final phase = (animation.value * 2 * math.pi) + (i * 0.45);
              final height = 5 + (math.sin(phase).abs() * 22);
              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: AppColors.deepTeal, borderRadius: BorderRadius.circular(2)),
              );
            }),
          ),
        );
      },
    );
  }
}