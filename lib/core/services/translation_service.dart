import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranslationService {
  final String _apiKey = dotenv.env['GOOGLE_TRANSLATE_API_KEY'] ?? '';

  Future<String> translate({
    required String text,
    required String targetLanguage,
    int maxRetries = 3,
  }) async {
    if (text.trim().isEmpty) return '';

    final uri = Uri.parse('https://translation.googleapis.com/language/translate/v2');

    int attempt = 0;
    while (true) {
      try {
        final response = await http.post(
          uri,
          body: {
            'key': _apiKey,
            'q': text,
            'target': targetLanguage,
            'format': 'text',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['data']['translations'][0]['translatedText'] as String;
        } else {
          throw Exception('Translation API error ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        attempt++;
        final isRetryable = e.toString().contains('503') || e.toString().contains('UNAVAILABLE');
        if (!isRetryable || attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }
}