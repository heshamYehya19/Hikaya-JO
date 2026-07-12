import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/journey_service.dart';
import '../models/journey.dart';

final journeyServiceProvider = Provider<JourneyService>((ref) => JourneyService());

final currentJourneyProvider = StateProvider<Journey?>((ref) => null);