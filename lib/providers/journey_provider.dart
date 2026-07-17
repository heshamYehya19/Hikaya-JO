import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/journey_service.dart';
import '../models/journey.dart';
import '../models/destination.dart';
import 'story_guide_provider.dart';

final journeyServiceProvider = Provider<JourneyService>((ref) => JourneyService());

final currentJourneyProvider = StateProvider<Journey?>((ref) => null);

/// Used by the Home screen's "Popular Destinations" row.
final allDestinationsProvider = FutureProvider<List<Destination>>((ref) {
  return ref.read(journeyServiceProvider).fetchAllDestinations();
});

/// Used by the Home screen's "Continue Your Journey" card — most recent
/// saved journey, or null if the user hasn't generated one yet.
final latestJourneyProvider = FutureProvider<Journey?>((ref) async {
  final journeys = await ref.read(journeyServiceProvider).fetchUserJourneys();
  return journeys.isNotEmpty ? journeys.first : null;
});

/// Home screen hero background. Petra is the featured destination — once
/// you add its imageUrls in Firestore (see seed_service.dart), this photo
/// shows up automatically. Reuses the same fetchDestination the detail
/// screen already calls, rather than adding a duplicate method.
final featuredDestinationProvider = FutureProvider<Destination?>((ref) {
  return ref.read(storyGuideServiceProvider).fetchDestination('petra');
});