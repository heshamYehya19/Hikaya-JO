import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/destination.dart';
import 'offline_service.dart';

class StoryGuideService {
  late final GenerativeModel _model;
  final _firestore = FirebaseFirestore.instance;

  StoryGuideService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash-lite';
    _model = GenerativeModel(model: modelName, apiKey: apiKey);
  }

  Future<Destination?> fetchDestination(String id) async {
    final doc = await _firestore.collection('destinations').doc(id).get();
    if (!doc.exists) return null;
    return Destination.fromMap(doc.id, doc.data()!);
  }

  /// Returns a short AI-generated narrative for [destination].
  /// Caches the result in Firestore so it's only generated once per destination —
  /// saves API calls and makes every visit after the first instant.
  Future<String> getStory(Destination destination, {int maxRetries = 3}) async {
    final offlineService = OfflineService();
    final online = await offlineService.isOnline();

    if (!online) {
      final cached = offlineService.getCachedStory(destination.id);
      if (cached != null) return cached;
      return 'This story isn\'t downloaded yet — connect to the internet to view it.';
    }

    final docRef = _firestore.collection('destinations').doc(destination.id);
    final doc = await docRef.get();
    final cached = doc.data()?['aiStory'] as String?;
    if (cached != null && cached.trim().isNotEmpty) return cached;

    final prompt = '''
Write a short, engaging 3-4 sentence story-style narrative about ${destination.name}, Jordan for a tourist visiting right now.
Weave in one interesting historical or cultural detail. Write in a warm, conversational tone — like a knowledgeable local friend, not a textbook.
Do not use markdown formatting. Return only the narrative text.

Context: ${destination.description}
''';

    int attempt = 0;
    while (true) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        final story = response.text?.trim() ?? 'Story unavailable right now — please try again later.';
        await docRef.update({'aiStory': story});
        return story;
      } catch (e) {
        attempt++;
        final isRetryable = e.toString().contains('503') || e.toString().contains('UNAVAILABLE');
        if (!isRetryable || attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }
}