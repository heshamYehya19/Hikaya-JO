import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/colors.dart';
import '../../providers/translation_provider.dart';

enum TalkDirection { touristToLocal, localToTourist }

class HikayaTalkScreen extends ConsumerStatefulWidget {
  const HikayaTalkScreen({super.key});

  @override
  ConsumerState<HikayaTalkScreen> createState() => _HikayaTalkScreenState();
}

class _HikayaTalkScreenState extends ConsumerState<HikayaTalkScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  int _requestId = 0;

  TalkDirection _direction = TalkDirection.touristToLocal;
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isTranslating = false;

  String _recognizedText = '';
  String _translatedText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
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

  // Locale for speech recognition input
  String get _inputLocale =>
      _direction == TalkDirection.touristToLocal ? 'en-US' : 'ar-JO';

  // Target language name for the Gemini translation prompt
  String get _targetLanguage =>
      _direction == TalkDirection.touristToLocal ? 'ar' : 'en';

  // TTS output language
  String get _outputLocale =>
      _direction == TalkDirection.touristToLocal ? 'ar-SA' : 'en-US';

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


    setState(() {
      _recognizedText = '';
      _translatedText = '';
      _isListening = true;
    });

    await _speech.listen(
      localeId: _inputLocale,
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
        targetLanguage: _targetLanguage,
      );

      // Only apply this result if no newer request has started since
      if (thisRequestId != _requestId) return;

      setState(() {
        _translatedText = translated;
        _isTranslating = false;
      });

      await _tts.setLanguage(_outputLocale);
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

  void _swapDirection() {
    setState(() {
      _direction = _direction == TalkDirection.touristToLocal
          ? TalkDirection.localToTourist
          : TalkDirection.touristToLocal;
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
    final isTouristSpeaking = _direction == TalkDirection.touristToLocal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hikaya Talk')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Direction toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.duneLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isTouristSpeaking ? null : _swapDirection,
                        child: _DirectionChip(
                          label: '🇬🇧 → 🇯🇴',
                          selected: isTouristSpeaking,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: !isTouristSpeaking ? null : _swapDirection,
                        child: _DirectionChip(
                          label: '🇯🇴 → 🇬🇧',
                          selected: !isTouristSpeaking,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recognized text card
              _TranscriptCard(
                label: isTouristSpeaking ? 'You said (English)' : 'You said (Arabic)',
                text: _recognizedText.isEmpty ? 'Tap the mic and start speaking…' : _recognizedText,
                isPlaceholder: _recognizedText.isEmpty,
              ),
              const SizedBox(height: 16),

              // Translated text card
              _TranscriptCard(
                label: isTouristSpeaking ? 'Translated (Arabic)' : 'Translated (English)',
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
                    color: Colors.white,
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

class _DirectionChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _DirectionChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.deepTeal : Colors.transparent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
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