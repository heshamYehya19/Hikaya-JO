import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/business.dart';

class BusinessSeedService {
  final _firestore = FirebaseFirestore.instance;

  final List<Business> _businesses = [
    Business(
      id: 'biz_petra_cafe',
      name: 'Petra Kitchen',
      type: 'restaurant',
      destinationId: 'petra',
      description: 'Traditional Jordanian cooking experience near the Petra entrance.',
      offer: '15% off a Jordanian cooking class',
      coinsRequired: 25,
    ),
    Business(
      id: 'biz_petra_guide',
      name: 'Petra Local Guides Co-op',
      type: 'guide',
      destinationId: 'petra',
      description: 'Licensed local guides offering in-depth historical tours of Petra.',
      offer: 'Free 30-minute guide add-on',
      coinsRequired: 40,
    ),
    Business(
      id: 'biz_wadirum_camp',
      name: 'Rum Stars Desert Camp',
      type: 'shop',
      destinationId: 'wadi_rum',
      description: 'Bedouin-run desert camp offering overnight stays and jeep tours.',
      offer: '10% off overnight desert camp stay',
      coinsRequired: 30,
    ),
    Business(
      id: 'biz_amman_artisan',
      name: 'Jara Souvenirs',
      type: 'artisan',
      destinationId: 'amman_citadel',
      description: 'Handmade Jordanian crafts, mosaics, and olive wood carvings.',
      offer: '10% off handmade souvenirs',
      coinsRequired: 15,
    ),
    Business(
      id: 'biz_jerash_restaurant',
      name: 'Lebanese House Jerash',
      type: 'restaurant',
      destinationId: 'jerash',
      description: 'Local restaurant serving traditional Levantine dishes near the ruins.',
      offer: 'Free dessert with any meal',
      coinsRequired: 15,
    ),
    Business(
      id: 'biz_deadsea_spa',
      name: 'Dead Sea Mineral Spa',
      type: 'shop',
      destinationId: 'dead_sea',
      description: 'Mud and mineral products sourced directly from the Dead Sea.',
      offer: '20% off mineral mud products',
      coinsRequired: 20,
    ),
    Business(
      id: 'biz_ajloun_guide',
      name: 'Ajloun Heritage Tours',
      type: 'guide',
      destinationId: 'ajloun_castle',
      description: 'Community-run tours through Ajloun\'s forests and castle grounds.',
      offer: 'Free trail map & guidebook',
      coinsRequired: 10,
    ),
  ];

  Future<void> seedBusinesses() async {
    final batch = _firestore.batch();
    for (final business in _businesses) {
      final ref = _firestore.collection('businesses').doc(business.id);
      batch.set(ref, business.toMap());
    }
    await batch.commit();
  }
}