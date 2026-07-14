import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/business.dart';

class BusinessService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<Business>> fetchBusinessesForDestination(String destinationId) async {
    final snapshot =
    await _firestore.collection('businesses').where('destinationId', isEqualTo: destinationId).get();
    return snapshot.docs.map((doc) => Business.fromMap(doc.id, doc.data())).toList();
  }

  Future<List<Business>> fetchAllBusinesses() async {
    final snapshot = await _firestore.collection('businesses').get();
    return snapshot.docs.map((doc) => Business.fromMap(doc.id, doc.data())).toList();
  }

  /// Attempts to redeem [business]'s offer using the user's coins.
  /// Returns null on success, or an error message string on failure.
  Future<String?> redeemOffer(Business business) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 'Not logged in';

    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<String?>((transaction) async {
      final userDoc = await transaction.get(userRef);
      final currentCoins = (userDoc.data()?['coins'] ?? 0) as int;

      if (currentCoins < business.coinsRequired) {
        return 'Not enough coins — need ${business.coinsRequired}, have $currentCoins';
      }

      transaction.update(userRef, {'coins': FieldValue.increment(-business.coinsRequired)});
      transaction.set(
        userRef.collection('redeemedOffers').doc(business.id),
        {'businessId': business.id, 'businessName': business.name, 'redeemedAt': FieldValue.serverTimestamp()},
      );
      return null; // success
    });
  }
}