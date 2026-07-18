import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'offline_service.dart';

class JourneyService {
  late final GenerativeModel _model;
  final _firestore = FirebaseFirestore.instance;

  JourneyService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash-lite';
    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        maxOutputTokens: 2048,
      ),
    );
  }

  Future<void> saveJourney(Journey journey) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('No logged-in user');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('journeys')
        .doc(journey.id)
        .set(journey.toMap());
  }

  Future<List<Journey>> fetchUserJourneys() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('journeys')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Journey.fromMap(doc.id, doc.data())).toList();
  }
  Future<List<Destination>> fetchAllDestinations() async {
    final offlineService = OfflineService();
    final online = await offlineService.isOnline();

    if (!online) {
      final cachedIds = Hive.box<String>('offline_destinations').keys;
      return cachedIds
          .map((id) => offlineService.getCachedDestination(id as String))
          .whereType<Destination>()
          .toList();
    }

    final snapshot = await _firestore.collection('destinations').get();
    return snapshot.docs.map((doc) => Destination.fromMap(doc.id, doc.data())).toList();
  }

  Future<Journey> generateJourney({
    required List<Destination> destinations,
    required List<String> interests,
    required String budgetLevel,
    required int availableHours,
    required String transportMode,
    int maxRetries = 3,
  }) async {
    if (destinations.isEmpty) {
      throw Exception('No destinations found — did you run the /seed screen?');
    }

    final destinationsJson = destinations
        .map((d) => {
      'id': d.id,
      'name': d.name,
      'type': d.type,
      'avgVisitMinutes': d.avgVisitMinutes,
      'costLevel': d.costLevel,
    })
        .toList();

    final prompt = '''
You are a Jordan travel planner. Choose the best subset of destinations from the list below to build a realistic day itinerary, and return ONLY valid JSON (no markdown, no explanation).

User preferences:
- Interests: ${interests.join(', ')}
- Budget level: $budgetLevel
- Available hours: $availableHours
- Transport mode: $transportMode

Available destinations (JSON):
${jsonEncode(destinationsJson)}

Return JSON in exactly this shape:
{
  "stops": [
    {
      "destinationId": "string, must match an id from the list above",
      "destinationName": "string",
      "suggestedTime": "e.g. 9:00 AM",
      "durationMinutes": number,
      "estimatedCost": number (JOD, rough estimate),
      "notes": "one short sentence on why this stop fits the user's interests"
    }
  ],
  "totalDurationMinutes": number,
  "totalCost": number
}

IMPORTANT: The user has $availableHours hours total (${availableHours * 60} minutes). Add up each stop's durationMinutes plus roughly 30 minutes of travel time between each pair of consecutive stops. The sum must not exceed ${availableHours * 60} minutes. Choose fewer stops if needed to stay within this budget — do not include a stop unless it fits.
''';

    int attempt = 0;
    while (true) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        final rawText = response.text?.trim() ?? '{}';

        final parsed = jsonDecode(rawText) as Map<String, dynamic>;

        final stops = (parsed['stops'] as List)
            .map((s) => JourneyStop.fromMap(s as Map<String, dynamic>))
            .toList();

        final visitMinutes = stops.fold<int>(0, (sum, stop) => sum + stop.durationMinutes);
        final estimatedTravelMinutes = stops.length > 1 ? (stops.length - 1) * 30 : 0;
        final computedTotalDuration = visitMinutes + estimatedTravelMinutes;
        final computedTotalCost = stops.fold<double>(0, (sum, stop) => sum + stop.estimatedCost);

        return Journey(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          stops: stops,
          totalDurationMinutes: computedTotalDuration,
          totalCost: computedTotalCost,
          createdAt: DateTime.now(),
        );
      } catch (e) {
        attempt++;
        final isRetryable = e.toString().contains('503') || e.toString().contains('UNAVAILABLE');
        if (!isRetryable || attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }
}