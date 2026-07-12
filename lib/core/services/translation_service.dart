import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranslationService {
  late final GenerativeModel _model;

  TranslationService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash-lite';
    _model = GenerativeModel(model: modelName, apiKey: apiKey);
  }

  Future<String> translate({
    required String text,
    required String targetLanguage,
    int maxRetries = 3,
  }) async  {
    if (text.trim().isEmpty) return '';

    final stopwatch = Stopwatch()..start();
    final prompt = 'Translate the following text to $targetLanguage. '
        'Reply with ONLY the translated text — no quotes, no explanation, no extra words:\n\n$text';

    int attempt = 0;
    while (true) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        print('DEBUG: translation took ${stopwatch.elapsedMilliseconds}ms, attempt #$attempt');
        return response.text?.trim() ?? '';
      } catch (e) {
        attempt++;
        print('DEBUG: attempt $attempt failed after ${stopwatch.elapsedMilliseconds}ms: $e');
        final isRetryable = e.toString().contains('503') || e.toString().contains('UNAVAILABLE');
        if (!isRetryable || attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
  }
}