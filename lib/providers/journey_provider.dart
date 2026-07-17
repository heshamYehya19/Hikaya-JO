import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/journey_service.dart';
import '../models/journey.dart';
import '../models/destination.dart';

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