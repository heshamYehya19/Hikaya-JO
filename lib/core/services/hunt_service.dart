import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/challenge.dart';

class HuntService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<Challenge>> fetchChallenges() async {
    final snapshot = await _firestore.collection('challenges').get();
    return snapshot.docs.map((doc) => Challenge.fromMap(doc.id, doc.data())).toList();
  }

  Future<Set<String>> fetchCompletedChallengeIds() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};
    final snapshot =
    await _firestore.collection('users').doc(userId).collection('completedChallenges').get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  /// Awards coins + badge for [challenge]. Idempotent — returns false without
  /// re-awarding if this challenge was already completed by this user.
  Future<bool> completeChallenge(Challenge challenge) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('No logged-in user');

    final completedRef =
    _firestore.collection('users').doc(userId).collection('completedChallenges').doc(challenge.id);

    final existing = await completedRef.get();
    if (existing.exists) return false;

    final userRef = _firestore.collection('users').doc(userId);

    final batch = _firestore.batch();
    batch.set(completedRef, {
      'challengeId': challenge.id,
      'destinationId': challenge.destinationId,
      'completedAt': FieldValue.serverTimestamp(),
    });
    batch.update(userRef, {
      'coins': FieldValue.increment(challenge.rewardCoins),
      'badges': FieldValue.arrayUnion([challenge.badgeName]),
      'visitedLocations': FieldValue.arrayUnion([challenge.destinationId]),
    });
    await batch.commit();
    return true;
  }
}