import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Decides where a signed-in user should land: 'interestsSetup' if they
/// haven't completed the mandatory interest picker yet, otherwise 'home'.
/// Defaults to 'home' on any read failure (e.g. offline) so already-
/// onboarded returning users aren't blocked by a network hiccup.
class ProfileSetupService {
  Future<String> resolvePostAuthRoute() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 'home';
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final interests = List<String>.from(doc.data()?['interests'] ?? []);
      return interests.isEmpty ? 'interestsSetup' : 'home';
    } catch (e) {
      return 'home';
    }
  }
}