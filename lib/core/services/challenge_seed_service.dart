import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/challenge.dart';

class ChallengeSeedService {
  final _firestore = FirebaseFirestore.instance;

  final List<Challenge> _challenges = [
    Challenge(
      id: 'hunt_petra',
      destinationId: 'petra',
      destinationName: 'Petra',
      title: 'Find the Treasury',
      description: 'Stand before Al-Khazneh and snap a photo to prove you\'ve arrived at Jordan\'s most iconic site.',
      latitude: 30.3285,
      longitude: 35.4444,
      rewardCoins: 30,
      badgeName: 'Treasury Hunter',
    ),
    Challenge(
      id: 'hunt_wadi_rum',
      destinationId: 'wadi_rum',
      destinationName: 'Wadi Rum',
      title: 'Capture the Red Desert',
      description: 'Photograph the sandstone cliffs of the Valley of the Moon.',
      latitude: 29.5324,
      longitude: 35.4206,
      rewardCoins: 20,
      badgeName: 'Desert Wanderer',
    ),
    Challenge(
      id: 'hunt_jerash',
      destinationId: 'jerash',
      destinationName: 'Jerash',
      title: 'Walk the Colonnade',
      description: 'Capture the ancient Roman columns of Jerash.',
      latitude: 32.2811,
      longitude: 35.8993,
      rewardCoins: 20,
      badgeName: 'Time Traveler',
    ),
    Challenge(
      id: 'hunt_amman_citadel',
      destinationId: 'amman_citadel',
      destinationName: 'Amman Citadel',
      title: 'Overlook the Capital',
      description: 'Reach the hilltop Citadel and capture Amman spread out below.',
      latitude: 31.9552,
      longitude: 35.9351,
      rewardCoins: 15,
      badgeName: 'City Explorer',
    ),
    Challenge(
      id: 'hunt_dead_sea',
      destinationId: 'dead_sea',
      destinationName: 'Dead Sea',
      title: 'Float at the Lowest Point on Earth',
      description: 'Reach the shore of the Dead Sea, the lowest point on Earth\'s surface.',
      latitude: 31.7500,
      longitude: 35.5500,
      rewardCoins: 20,
      badgeName: 'Buoyant Traveler',
    ),
    Challenge(
      id: 'hunt_ajloun',
      destinationId: 'ajloun_castle',
      destinationName: 'Ajloun Castle',
      title: 'Defend the Hilltop Fortress',
      description: 'Reach the 12th-century castle built to fend off Crusader armies.',
      latitude: 32.3325,
      longitude: 35.7517,
      rewardCoins: 25,
      badgeName: 'Hidden Gem Hunter',
    ),
    Challenge(
      id: 'hunt_mount_nebo',
      destinationId: 'mount_nebo',
      destinationName: 'Mount Nebo',
      title: 'View the Promised Land',
      description: 'Stand where Moses is said to have viewed the Promised Land.',
      latitude: 31.7686,
      longitude: 35.7256,
      rewardCoins: 15,
      badgeName: 'Pilgrim',
    ),
  ];

  Future<void> seedChallenges() async {
    final batch = _firestore.batch();
    for (final challenge in _challenges) {
      final ref = _firestore.collection('challenges').doc(challenge.id);
      batch.set(ref, challenge.toMap());
    }
    await batch.commit();
  }
}