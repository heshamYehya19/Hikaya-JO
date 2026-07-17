import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PhotoVerificationResult {
  final bool plausible;
  final String reason;
  PhotoVerificationResult({required this.plausible, required this.reason});
}

/// Loose plausibility check for Hikaya Hunt challenge photos.
///
/// This is deliberately NOT an exact match against a reference photo —
/// two real photos of the same place will never pixel-match (different
/// angle, lighting, weather, time of day). Real geocaching/scavenger-hunt
/// apps rely on GPS proximity as the actual anti-cheat mechanism (you
/// already have that — see the geofence check in challenge_detail_screen.dart).
///
/// This just catches the obvious cases: someone submitting an indoor selfie,
/// a screenshot, or an unrelated object for a "photograph the ruins"
/// challenge. Reuses your existing Gemini setup — gemini-2.5-flash-lite is
/// multimodal, so no new API key or package needed.
class PhotoVerificationService {
  late final GenerativeModel _model;

  PhotoVerificationService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash-lite';
    _model = GenerativeModel(model: modelName, apiKey: apiKey);
  }

  Future<PhotoVerificationResult> verifyPhoto({
    required File photo,
    required String challengeTitle,
    required String challengeDescription,
    required String destinationName,
  }) async {
    final bytes = await photo.readAsBytes();

    final prompt = '''
You're a lightweight sanity-check for a Jordan tourism scavenger hunt app.
A user submitted a photo for this challenge:

Destination: $destinationName
Challenge: $challengeTitle
Description: $challengeDescription

Does this photo plausibly show the user at or near this kind of location/subject?
Be lenient — different angles, lighting, weather, and partial/zoomed-in views are
all fine. Only flag it as implausible if the photo is clearly unrelated: an indoor
selfie, a random object, a screenshot, or a completely different type of place.

Return ONLY valid JSON, no markdown, no explanation outside the JSON:
{"plausible": true or false, "reason": "one short sentence"}
''';

    try {
      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ]);

      final raw = response.text?.trim() ?? '';
      final cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      return PhotoVerificationResult(
        plausible: parsed['plausible'] == true,
        reason: parsed['reason']?.toString() ?? '',
      );
    } catch (e) {
      // Fail open — never block a legitimate user just because the AI
      // call hiccuped (network blip, rate limit, unexpected response shape).
      return PhotoVerificationResult(plausible: true, reason: 'Verification unavailable');
    }
  }
}