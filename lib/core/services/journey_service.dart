import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/destination.dart';
import '../../models/journey.dart';

class JourneyService {
  late final GenerativeModel _model;
  final _firestore = FirebaseFirestore.instance;

  JourneyService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash-lite';
    _model = GenerativeModel(model: modelName, apiKey: apiKey);
  }

  Future<List<Destination>> fetchAllDestinations() async {
    final snapshot = await _firestore.collection('destinations').get();
    return snapshot.docs.map((doc) => Destination.fromMap(doc.id, doc.data())).toList();
  }

  Future<Journey> generateJourney({
    required List<String> interests,
    required String budgetLevel, // "low", "medium", "high"
    required int availableHours,
    required String transportMode, // "car", "public", "walking"
  }) async {
    final destinations = await fetchAllDestinations();

    final destinationsJson = destinations
        .map((d) => {
      'id': d.id,
      'name': d.name,
      'type': d.type,
      'description': d.description,
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

Only include stops that realistically fit within $availableHours hours total, accounting for travel time between locations via $transportMode.
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final rawText = response.text?.trim() ?? '{}';

    // Strip markdown code fences if Gemini adds them despite instructions
    final cleaned = rawText.replaceAll(RegExp(r'```json|```'), '').trim();

    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    final stops = (parsed['stops'] as List)
        .map((s) => JourneyStop.fromMap(s as Map<String, dynamic>))
        .toList();

    return Journey(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      stops: stops,
      totalDurationMinutes: parsed['totalDurationMinutes'] ?? 0,
      totalCost: (parsed['totalCost'] ?? 0).toDouble(),
      createdAt: DateTime.now(),
    );
  }
}