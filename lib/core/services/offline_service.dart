import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Every cached entry is prefixed with the signed-in user's uid, so
  /// switching accounts on the same device never surfaces one user's
  /// downloaded journeys to another. Falls back to 'guest' only if this
  /// somehow gets called with nobody signed in.
  String get _userPrefix => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  Future<void> cacheJourney({
    required Journey journey,
    required List<Destination> destinations,
    required Map<String, String> stories,
  }) async {
    final prefix = _userPrefix;
    await _journeys.put('$prefix::${journey.id}', jsonEncode(journey.toMap()));
    for (final d in destinations) {
      await _destinations.put('$prefix::${d.id}', jsonEncode(d.toMap()));
    }
    for (final entry in stories.entries) {
      await _stories.put('$prefix::${entry.key}', entry.value);
    }
    await _cacheImages(destinations);
  }

  /// Pre-downloads every image for each destination into the
  /// CachedNetworkImage disk cache, so "Download Offline" actually means
  /// offline-ready — not dependent on the user having already browsed to
  /// a screen that happened to load that image online first. Failures are
  /// swallowed per-image so one broken URL doesn't block the whole download.
  /// Not user-scoped on purpose — a destination photo isn't private, and
  /// sharing it across accounts avoids redundant downloads.
  Future<void> _cacheImages(List<Destination> destinations) async {
    final cacheManager = DefaultCacheManager();
    for (final d in destinations) {
      for (final url in d.imageUrls) {
        try {
          final existing = await cacheManager.getFileFromCache(url);
          if (existing != null) continue; // already cached, skip the network hit
          await cacheManager.downloadFile(url);
        } catch (_) {
          // Skip — that one image just won't be available offline.
        }
      }
    }
  }
  bool isJourneyCached(String journeyId) => _journeys.containsKey('$_userPrefix::$journeyId');

  List<Journey> getCachedJourneys() {
    final prefix = '$_userPrefix::';
    return _journeys.keys
        .where((key) => (key as String).startsWith(prefix))
        .map((key) {
      final raw = _journeys.get(key) as String;
      final journeyId = (key as String).substring(prefix.length);
      return Journey.fromMap(journeyId, jsonDecode(raw) as Map<String, dynamic>);
    }).toList();
  }

  Destination? getCachedDestination(String id) {
    final raw = _destinations.get('$_userPrefix::$id');
    if (raw == null) return null;
    return Destination.fromMap(id, jsonDecode(raw) as Map<String, dynamic>);
  }

  String? getCachedStory(String destinationId) => _stories.get('$_userPrefix::$destinationId');

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map((r) => !r.contains(ConnectivityResult.none));
  }

  List<Destination> getAllCachedDestinations() {
    final prefix = '$_userPrefix::';
    return _destinations.keys
        .where((key) => (key as String).startsWith(prefix))
        .map((key) {
      final raw = _destinations.get(key) as String;
      final destinationId = (key as String).substring(prefix.length);
      return Destination.fromMap(destinationId, jsonDecode(raw) as Map<String, dynamic>);
    }).toList();
  }

  /// Caches the full destination catalog for offline browsing (Home's
  /// "Popular Destinations" etc.), independent of any specific downloaded
  /// journey. Called automatically whenever fetchAllDestinations() succeeds
  /// online — see journey_service.dart — so the offline catalog silently
  /// stays fresh without a separate "download everything" action. Writes
  /// to the same box/key scheme as cacheJourney(), so results from both
  /// naturally merge — getAllCachedDestinations() returns the union.
  Future<void> cacheAllDestinations(List<Destination> destinations) async {
    final prefix = _userPrefix;
    for (final d in destinations) {
      await _destinations.put('$prefix::${d.id}', jsonEncode(d.toMap()));
    }
    await _cacheImages(destinations);
  }
}