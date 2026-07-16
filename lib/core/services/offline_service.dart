import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/journey.dart';
import '../../models/destination.dart';

class OfflineService {
  static const _journeysBox = 'offline_journeys';
  static const _destinationsBox = 'offline_destinations';
  static const _storiesBox = 'offline_stories';

  static Future<void> init() async {
    await Hive.openBox<String>(_journeysBox);
    await Hive.openBox<String>(_destinationsBox);
    await Hive.openBox<String>(_storiesBox);
  }

  Box<String> get _journeys => Hive.box<String>(_journeysBox);
  Box<String> get _destinations => Hive.box<String>(_destinationsBox);
  Box<String> get _stories => Hive.box<String>(_storiesBox);

  Future<void> cacheJourney({
    required Journey journey,
    required List<Destination> destinations,
    required Map<String, String> stories,
  }) async {
    await _journeys.put(journey.id, jsonEncode(journey.toMap()));
    for (final d in destinations) {
      await _destinations.put(d.id, jsonEncode(d.toMap()));
    }
    for (final entry in stories.entries) {
      await _stories.put(entry.key, entry.value);
    }
  }

  bool isJourneyCached(String journeyId) => _journeys.containsKey(journeyId);

  List<Journey> getCachedJourneys() {
    return _journeys.keys.map((key) {
      final raw = _journeys.get(key) as String;
      return Journey.fromMap(key as String, jsonDecode(raw) as Map<String, dynamic>);
    }).toList();
  }

  Destination? getCachedDestination(String id) {
    final raw = _destinations.get(id);
    if (raw == null) return null;
    return Destination.fromMap(id, jsonDecode(raw) as Map<String, dynamic>);
  }

  String? getCachedStory(String destinationId) => _stories.get(destinationId);

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map((r) => !r.contains(ConnectivityResult.none));
  }
}