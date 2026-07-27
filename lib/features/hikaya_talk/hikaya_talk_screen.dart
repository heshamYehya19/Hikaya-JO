import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/localization/app_locale.dart';
import '../../providers/translation_provider.dart';
import '../../models/talk_language.dart';

class HikayaTalkScreen extends ConsumerStatefulWidget {
  const HikayaTalkScreen({super.key});

  @override
  ConsumerState<HikayaTalkScreen> createState() => _HikayaTalkScreenState();
}

class _HikayaTalkScreenState extends ConsumerState<HikayaTalkScreen> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  int _requestId = 0;

  late final AnimationController _pulseController;
  bool _micPressed = false;
  double _swapTurns = 0;

  TalkLanguage _myLanguage = kTalkLanguages[0]; // English, until the saved default loads
  TalkLanguage _theirLanguage = kTalkLanguages[1]; // Arabic
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isTranslating = false;

  String _recognizedText = '';
  String _translatedText = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _initSpeech();
    _loadSavedLanguages();
  }

  /// Loads the default "I Speak" / "They Speak" languages saved from the
  /// Profile screen, if the user has set one. One-time read (not a stream)
  /// since this is just an initial value — changing languages here doesn't
  /// need to live-sync back to Profile.
  Future<void> _loadSavedLanguages() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null || !mounted) return;

      setState(() {
        _myLanguage = talkLanguageFromCode(data['myLanguage'] as String?, fallback: _myLanguage);
        _theirLanguage = talkLanguageFromCode(data['theirLanguage'] as String?, fallback: _theirLanguage);
      });
    } catch (_) {
      // No saved preference yet, or offline — the English/Arabic defaults are fine.
    }
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) return;
    }

    _requestId++; // invalidate any in-flight translation from a previous question

    setState(() {
      _recognizedText = '';
      _translatedText = '';
      _isListening = true;
    });

    await _speech.listen(
      localeId: _myLanguage.speechLocale,
      onResult: (result) async {
        setState(() => _recognizedText = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          await _speech.stop();
          setState(() => _isListening = false);
          await _translateAndSpeak(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _translateAndSpeak(String text) async {
    final int thisRequestId = ++_requestId; // tag this specific request

    setState(() => _isTranslating = true);
    try {
      final translated = await ref.read(translationServiceProvider).translate(
        text: text,
        targetLanguage: _theirLanguage.translateCode,
      );

      // Only apply this result if no newer request has started since
      if (thisRequestId != _requestId) return;

      setState(() {
        _translatedText = translated;
        _isTranslating = false;
      });

      await _tts.setLanguage(_theirLanguage.ttsLocale);
      await _tts.speak(translated);
    } catch (e) {
      if (thisRequestId != _requestId) return; // ignore stale errors too

      setState(() {
        if (e.toString().contains('503') || e.toString().contains('UNAVAILABLE')) {
          _translatedText = AppLocale.of(context).t('talk_service_busy');
        } else {
          _translatedText = "Couldn't translate that — please try again";
        }
        _isTranslating = false;
      });
    }
  }

  Future<void> _replay() async {
    if (_translatedText.isEmpty) return;
    await _tts.setLanguage(_theirLanguage.ttsLocale);
    await _tts.speak(_translatedText);
  }

  void _swapLanguages() {
    setState(() {
      _swapTurns += 1;
      final temp = _myLanguage;
      _myLanguage = _theirLanguage;
      _theirLanguage = temp;
      _recognizedText = '';
      _translatedText = '';
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.of(context).t;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Column(
                children: [
                  Text(
                    t('talk_title'),
                    textAlign: TextAlign.center,
                    style: AppTypography.headline2.copyWith(fontSize: 20, color: AppColors.deepTeal),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Break the language barrier',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySecondary,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Compact pill language selectors + swap
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LanguagePill(
                    language: _myLanguage,
                    onChanged: (lang) => setState(() {
                      _myLanguage = lang;
                      _recognizedText = '';
                      _translatedText = '';
                    }),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppColors.deepTeal.withOpacity(0.15), shape: BoxShape.circle),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: _swapLanguages,
                      icon: AnimatedRotation(
                        turns: _swapTurns,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        child: const Icon(Icons.swap_horiz, color: AppColors.deepTeal, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _LanguagePill(
                    language: _theirLanguage,
                    onChanged: (lang) => setState(() {
                      _theirLanguage = lang;
                      _recognizedText = '';
                      _translatedText = '';
                    }),
                  ),
                ],
              ),

              // Big centered transcript — the reference's main focal area
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _recognizedText.isEmpty ? t('talk_tap_to_speak_hint') : _recognizedText,
                            key: ValueKey('recognized-$_recognizedText'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: _recognizedText.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                              fontStyle: _recognizedText.isEmpty ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ),
                        if (_isListening) ...[
                          const SizedBox(height: 28),
                          _Waveform(animation: _pulseController),
                        ],
                        if (_translatedText.isNotEmpty || _isTranslating) ...[
                          const SizedBox(height: 32),
                          Container(height: 1, width: 60, color: AppColors.duneLight),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Column(
                              key: ValueKey('translated-$_translatedText-$_isTranslating'),
                              children: [
                                Text(
                                  _isTranslating ? t('talk_translating') : _translatedText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: AppColors.deepTeal,
                                  ),
                                ),
                                if (!_isTranslating && _translatedText.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  GestureDetector(
                                    onTap: _replay,
                                    child: const Icon(Icons.volume_up_rounded, color: AppColors.deepTeal, size: 22),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Mic button
              GestureDetector(
                onTapDown: (_) => setState(() => _micPressed = true),
                onTapUp: (_) => setState(() => _micPressed = false),
                onTapCancel: () => setState(() => _micPressed = false),
                onTap: _isTranslating ? null : (_isListening ? _stopListening : _startListening),
                child: AnimatedScale(
                  scale: _micPressed ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? AppColors.error : AppColors.deepTeal,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? AppColors.error : AppColors.deepTeal).withOpacity(0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: AppColors.background,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isListening ? t('talk_listening') : t('talk_tap_to_speak'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact flag+name+chevron pill — a lighter-weight alternative to the
/// boxed LanguagePicker used on Profile. Local to this screen so Profile's
/// picker (which is shared/reused there) stays untouched.
class _LanguagePill extends StatelessWidget {
  final TalkLanguage language;
  final ValueChanged<TalkLanguage> onChanged;
  const _LanguagePill({required this.language, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TalkLanguage>(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onChanged,
      itemBuilder: (context) => kTalkLanguages
          .map((lang) => PopupMenuItem(
        value: lang,
        child: Text('${lang.flag}  ${lang.name}', style: const TextStyle(color: AppColors.textPrimary)),
      ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.duneLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(language.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Animated bar waveform, shown only while actively listening — each bar
/// oscillates on its own phase offset so it reads as organic rather than
/// a single wave moving in lockstep.
class _Waveform extends StatelessWidget {
  final Animation<double> animation;
  const _Waveform({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(20, (i) {
              final phase = (animation.value * 2 * math.pi) + (i * 0.5);
              final height = 6 + (math.sin(phase).abs() * 26);
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