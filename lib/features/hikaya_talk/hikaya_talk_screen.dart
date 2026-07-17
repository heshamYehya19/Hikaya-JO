import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/colors.dart';
import '../../providers/translation_provider.dart';
import '../../models/talk_language.dart';
import '../../widgets/language_picker.dart';

class HikayaTalkScreen extends ConsumerStatefulWidget {
  const HikayaTalkScreen({super.key});

  @override
  ConsumerState<HikayaTalkScreen> createState() => _HikayaTalkScreenState();
}

class _HikayaTalkScreenState extends ConsumerState<HikayaTalkScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  int _requestId = 0;

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
          _translatedText = 'Translation service is busy — please try again in a moment';
        } else {
          _translatedText = 'RAW ERROR: $e';
        }
        _isTranslating = false;
      });
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _myLanguage;
      _myLanguage = _theirLanguage;
      _theirLanguage = temp;
      _recognizedText = '';
      _translatedText = '';
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hikaya Talk')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Language selectors: "I Speak" / "They Speak"
              Row(
                children: [
                  Expanded(
                    child: LanguagePicker(
                      label: 'I Speak',
                      language: _myLanguage,
                      onChanged: (lang) => setState(() {
                        _myLanguage = lang;
                        _recognizedText = '';
                        _translatedText = '';
                      }),
                    ),
                  ),
                  IconButton(
                    onPressed: _swapLanguages,
                    icon: const Icon(Icons.swap_horiz, color: AppColors.deepTeal),
                  ),
                  Expanded(
                    child: LanguagePicker(
                      label: 'They Speak',
                      language: _theirLanguage,
                      onChanged: (lang) => setState(() {
                        _theirLanguage = lang;
                        _recognizedText = '';
                        _translatedText = '';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recognized text card
              _TranscriptCard(
                label: 'You said (${_myLanguage.name})',
                text: _recognizedText.isEmpty ? 'Tap the mic and start speaking…' : _recognizedText,
                isPlaceholder: _recognizedText.isEmpty,
              ),
              const SizedBox(height: 16),

              // Translated text card
              _TranscriptCard(
                label: 'Translated (${_theirLanguage.name})',
                text: _isTranslating
                    ? 'Translating…'
                    : (_translatedText.isEmpty ? 'Translation will appear here' : _translatedText),
                isPlaceholder: _translatedText.isEmpty && !_isTranslating,
                accent: true,
              ),

              const Spacer(),

              // Mic button
              GestureDetector(
                onTap: _isTranslating ? null : (_isListening ? _stopListening : _startListening),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? AppColors.error : AppColors.deepTeal,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? AppColors.error : AppColors.deepTeal).withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: AppColors.background,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isListening ? 'Listening…' : 'Tap to speak',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final String label;
  final String text;
  final bool isPlaceholder;
  final bool accent;

  const _TranscriptCard({
    required this.label,
    required this.text,
    required this.isPlaceholder,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ? AppColors.teal.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent ? AppColors.teal.withOpacity(0.3) : AppColors.duneLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isPlaceholder ? AppColors.textSecondary : AppColors.textPrimary,
              fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}