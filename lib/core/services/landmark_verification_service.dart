import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'location_service.dart';

class LandmarkVerificationResult {
  final bool landmarkFound; // Vision API recognized ANY landmark in the photo
  final bool matched; // that landmark's coordinates are near the challenge target
  final String? landmarkName;
  final double? distanceMeters;

  LandmarkVerificationResult({
    required this.landmarkFound,
    required this.matched,
    this.landmarkName,
    this.distanceMeters,
  });
}

/// Uses Cloud Vision's Landmark Detection for genuine photo verification —
/// not a plausibility guess like PhotoVerificationService (Gemini), but an
/// actual landmark identification with real GPS coordinates you can compare
/// against the challenge's target location.
///
/// Limitation: Google's landmark database only covers globally-recognized
/// sites. Petra, Jerash, and similar iconic spots should be recognized —
/// smaller destinations (Ajloun Castle, Umm Qais, Dana Reserve) likely
/// won't be. When landmarkFound is false, fall back to
/// PhotoVerificationService (Gemini) instead — see camera_capture_screen.dart.
class LandmarkVerificationService {
  final _locationService = LocationService();

  // Vision API's returned coordinates are for the landmark generally, not a
  // precise GPS pin — a few km of slack avoids false negatives on large
  // sites like Petra or Wadi Rum where the "center point" might be a
  // kilometer from where your challenge's coordinates are set.
  static const _matchRadiusMeters = 5000.0;

  Future<LandmarkVerificationResult> detectLandmark({
    required File photo,
    required double targetLat,
    required double targetLng,
  }) async {
    final apiKey = dotenv.env['CLOUD_VISION_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return LandmarkVerificationResult(landmarkFound: false, matched: false);
    }

    final bytes = await photo.readAsBytes();
    final base64Image = base64Encode(bytes);

    try {
      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'LANDMARK_DETECTION', 'maxResults': 5},
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        return LandmarkVerificationResult(landmarkFound: false, matched: false);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final annotations = (data['responses'] as List?)?.first['landmarkAnnotations'] as List?;

      if (annotations == null || annotations.isEmpty) {
        return LandmarkVerificationResult(landmarkFound: false, matched: false);
      }

      final top = annotations.first as Map<String, dynamic>;
      final locations = top['locations'] as List?;
      final name = top['description'] as String?;

      if (locations == null || locations.isEmpty) {
        return LandmarkVerificationResult(landmarkFound: true, matched: false, landmarkName: name);
      }

      final latLng = (locations.first as Map<String, dynamic>)['latLng'] as Map<String, dynamic>;
      final detectedLat = (latLng['latitude'] as num).toDouble();
      final detectedLng = (latLng['longitude'] as num).toDouble();

      final distance = _locationService.distanceToTarget(
        userLat: detectedLat,
        userLng: detectedLng,
        targetLat: targetLat,
        targetLng: targetLng,
      );

      return LandmarkVerificationResult(
        landmarkFound: true,
        matched: distance <= _matchRadiusMeters,
        landmarkName: name,
        distanceMeters: distance,
      );
    } catch (e) {
      // Fail open, same policy as PhotoVerificationService — a network
      // hiccup shouldn't block a legitimate submission.
      return LandmarkVerificationResult(landmarkFound: false, matched: false);
    }
  }
}