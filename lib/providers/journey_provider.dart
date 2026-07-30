import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/journey_service.dart';
import '../models/journey.dart';
import '../models/destination.dart';
import 'story_guide_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/offline_service.dart';

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
/// The interests picked on InterestsSetupScreen — used by Home to
/// personalize which destinations surface first.
final userInterestsProvider = FutureProvider<List<String>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return List<String>.from(doc.data()?['interests'] ?? []);
});

/// All of the user's saved journeys, newest first — falls back to the
/// offline cache if there's no connection. Used by Profile's "Your
/// Journeys" list. Kept as its own provider (rather than local State)
/// so it can be invalidated in one place right after a new journey is
/// saved — see journey_planner_input_screen.dart's _generate().
final userJourneysProvider = FutureProvider<List<Journey>>((ref) async {
  final offlineService = OfflineService();
  final online = await offlineService.isOnline();

  if (online) {
    try {
      return await ref.read(journeyServiceProvider).fetchUserJourneys();
    } catch (_) {
      // fall through to offline cache below
    }
  }
  return offlineService.getCachedJourneys();
});

/// Destination IDs the user has actually visited — via completing a
/// Hikaya Hunt challenge there, or listening to a story in person via
/// Story Mode. Used by Home's "Continue Your Journey" card to show real
/// progress, not a fabricated percentage.
final userVisitedLocationsProvider = FutureProvider<List<String>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return List<String>.from(doc.data()?['visitedLocations'] ?? []);
});

/// The user's display name from their Firestore profile doc — used by
/// Home's greeting instead of guessing something from their email.
final userNameProvider = FutureProvider<String?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return doc.data()?['name'] as String?;
});