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
  /// re-awarding if this challenge was already completed by this user. Runs
  /// as a transaction (not a plain batch) so the "already completed" check
  /// and the award itself are atomic — a batch's separate read-then-write
  /// leaves a window for a rapid double-submit to award twice.
  Future<bool> completeChallenge(Challenge challenge) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('No logged-in user');

    final completedRef =
    _firestore.collection('users').doc(userId).collection('completedChallenges').doc(challenge.id);
    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(completedRef);
      if (existing.exists) return false;

      transaction.set(completedRef, {
        'challengeId': challenge.id,
        'destinationId': challenge.destinationId,
        'completedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(userRef, {
        'coins': FieldValue.increment(challenge.rewardCoins),
        'badges': FieldValue.arrayUnion([challenge.badgeName]),
        'visitedLocations': FieldValue.arrayUnion([challenge.destinationId]),
      });
      return true;
    });
  }
}