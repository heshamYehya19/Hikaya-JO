import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/destination.dart';

class SeedService {
  final _firestore = FirebaseFirestore.instance;

  final List<Destination> _jordanDestinations = [
    Destination(
      id: 'petra',
      name: 'Petra',
      type: 'historical',
      latitude: 30.3285,
      longitude: 35.4444,
      description: 'Ancient rock-cut city and Jordan\'s most iconic UNESCO World Heritage Site, famous for the Treasury facade.',
      avgVisitMinutes: 240,
      costLevel: 'high',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Fpetra%2Fmain.jpg?alt=media&token=6461a51a-cace-403a-9e17-b8938880cf48"]
    ),
    Destination(
      id: 'wadi_rum',
      name: 'Wadi Rum',
      type: 'natural',
      latitude: 29.5324,
      longitude: 35.4206,
      description: 'A dramatic desert valley of red sand and towering sandstone mountains, known as the Valley of the Moon.',
      avgVisitMinutes: 180,
      costLevel: 'medium',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Fwadi_rum%2Fmain.jpg?alt=media&token=ae26e1b3-b124-42ef-9f2f-9f7d4c1422f8"]
    ),
    Destination(
      id: 'jerash',
      name: 'Jerash',
      type: 'historical',
      latitude: 32.2811,
      longitude: 35.8993,
      description: 'One of the best-preserved Roman provincial cities in the world, with colonnaded streets and ancient theatres.',
      avgVisitMinutes: 150,
      costLevel: 'medium',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Fjerash%2Fmain.jpg?alt=media&token=cb58a697-b366-45d9-b78a-bb27e59a248f"]

    ),
    Destination(
      id: 'amman_citadel',
      name: 'Amman Citadel',
      type: 'historical',
      latitude: 31.9552,
      longitude: 35.9351,
      description: 'A hilltop archaeological site overlooking downtown Amman, home to Roman, Byzantine, and Umayyad ruins.',
      avgVisitMinutes: 90,
      costLevel: 'low',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Famman_citadel%2Fmain.jpg?alt=media&token=9a9e5887-1f26-4b63-94b5-40b27665fd71"]

    ),
    Destination(
      id: 'dead_sea',
      name: 'Dead Sea',
      type: 'natural',
      latitude: 31.7500,
      longitude: 35.5500,
      description: 'The lowest point on Earth — famously buoyant, mineral-rich waters and therapeutic mud.',
      avgVisitMinutes: 150,
      costLevel: 'medium',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Fdead_sea%2Fmain.jpg?alt=media&token=ce36fb89-c005-466a-b8eb-31425a8d5a9a"]

    ),
    Destination(
      id: 'ajloun_castle',
      name: 'Ajloun Castle',
      type: 'historical',
      latitude: 32.3325,
      longitude: 35.7517,
      description: 'A 12th-century Islamic castle built to defend against Crusader armies, set on a forested hilltop.',
      isLesserKnown: true,
      avgVisitMinutes: 90,
      costLevel: 'low',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Fajloun_castle%2Fmain.jpg?alt=media&token=a6be2293-9e0d-45b6-ab91-9b9f018a594b"]

    ),
    Destination(
      id: 'umm_qais',
      name: 'Umm Qais',
      type: 'historical',
      latitude: 32.6564,
      longitude: 35.6850,
      description: 'Ruins of ancient Gadara with sweeping views over the Sea of Galilee, the Golan Heights, and the Yarmouk Valley.',
      isLesserKnown: true,
      avgVisitMinutes: 120,
      costLevel: 'low',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Fumm_qais%2Fmain.jpg?alt=media&token=24732a01-b8e4-4fe6-81b1-dcdeda14e0cf"]

    ),
    Destination(
      id: 'aqaba',
      name: 'Aqaba',
      type: 'natural',
      latitude: 29.5267,
      longitude: 35.0078,
      description: 'Jordan\'s only coastal city on the Red Sea, known for coral reefs and diving.',
      avgVisitMinutes: 180,
      costLevel: 'medium',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Faqaba%2Fmain.jpg?alt=media&token=d973e693-5960-42b6-b885-014b494c1e3b"]

    ),
    Destination(
      id: 'dana_reserve',
      name: 'Dana Biosphere Reserve',
      type: 'natural',
      latitude: 30.6761,
      longitude: 35.6289,
      description: 'Jordan\'s largest nature reserve, spanning dramatic cliffs, canyons, and diverse ecosystems.',
      isLesserKnown: true,
      avgVisitMinutes: 200,
      costLevel: 'low',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Fdana_reserve%2Fmain.jpg?alt=media&token=5ddf0072-cc0a-45fd-8369-25e8e6717309"]

    ),
    Destination(
      id: 'mount_nebo',
      name: 'Mount Nebo',
      type: 'cultural',
      latitude: 31.7686,
      longitude: 35.7256,
      description: 'A revered pilgrimage site believed to be where Moses viewed the Promised Land, with panoramic views of the Jordan Valley.',
      avgVisitMinutes: 60,
      costLevel: 'low',
      imageUrls: ["https://firebasestorage.googleapis.com/v0/b/hikaya-jo.firebasestorage.app/o/destinations%2Fmount_nebo%2Fmain.jpg?alt=media&token=024d5800-ff7a-4a60-b0ed-16056b228289"]

    ),
  ];

  /// Run this ONCE to populate Firestore. Safe to re-run — uses destination
  /// id as the doc id, so it overwrites rather than duplicates.
  Future<void> seedDestinations() async {
    final batch = _firestore.batch();
    for (final destination in _jordanDestinations) {
      final ref = _firestore.collection('destinations').doc(destination.id);
      batch.set(ref, destination.toMap());
    }
    await batch.commit();
  }
}