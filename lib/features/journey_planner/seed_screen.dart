import 'package:flutter/material.dart';
import '../../core/services/business_seed_service.dart';
import '../../core/services/seed_service.dart';
import '../../core/theme/colors.dart';
import '../../core/services/challenge_seed_service.dart';
import '../../models/destination.dart';
import '../../core/services/business_seed_service.dart';
import '../../models/business.dart';
import '../../models/challenge.dart';

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  bool _isSeeding = false;
  String _status = 'Not seeded yet';

  bool _isAddingSingle = false;
  String _singleStatus = '';

  bool _isAddingBusiness = false;
  String _businessStatus = '';

  bool _isAddingChallenges = false;
  String _challengesStatus = '';

  Future<void> _runSeed() async {
    setState(() {
      _isSeeding = true;
      _status = 'Seeding...';
    });
    try {
      await SeedService().seedDestinations();
      await ChallengeSeedService().seedChallenges();
      await BusinessSeedService().seedBusinesses();
      setState(() => _status = '✅ 10 destinations seeded successfully');
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      setState(() => _isSeeding = false);
    }
  }

  // Swap this Destination for the next one Claude gives you, then tap
  // the button below. Safe to run repeatedly — only ever touches this
  // one document, by its own id.
  Future<void> _addSingleDestination() async {
    setState(() {
      _isAddingSingle = true;
      _singleStatus = 'Adding...';
    });
    try {
      await SeedService().addDestination(
        Destination(
          id: 'wadi_mujib',
          name: 'Wadi Mujib',
          type: 'natural',
          latitude: 31.49278,
          longitude: 35.605,
          description: "A dramatic 70-kilometer canyon plunging into the Dead Sea, Wadi Mujib is Jordan's premier canyoning destination — wade, swim, and scramble through narrow sandstone gorges and waterfalls within a UNESCO biosphere reserve home to rare wildlife like the Nubian ibex and Syrian wolf.",
          isLesserKnown: true,
          avgVisitMinutes: 180,
          costLevel: 'medium',
          imageUrls: [], // add your uploaded Storage URLs here
        ),
      );
      setState(() => _singleStatus = '✅ Royal Botanic Garden added');
    } catch (e) {
      setState(() => _singleStatus = 'ERROR: $e');
    } finally {
      setState(() => _isAddingSingle = false);
    }
  }


  Future<void> _addSingleBusiness() async {
    setState(() {
      _isAddingBusiness = true;
      _businessStatus = 'Adding...';
    });
    try {
      await BusinessSeedService().addBusiness(
        Business(
          id: 'biz_aqaba_dive_center',
          name: 'Aqaba International Dive Center',
          type: 'guide',
          destinationId: 'aqaba_marine_reserve',
          description: 'Family-run dive center operating since 1975, offering PADI, CMAS, and SSI certified courses, guided reef and wreck dives, and beginner-friendly discovery dives across Aqaba\'s Red Sea coral reefs.',
          offer: 'Ask about Hikaya JO visitor rates',
          coinsRequired: 20,
          contactInfo: '+962 79 694 9082 (WhatsApp)',
        ),
      );
      setState(() => _businessStatus = '✅ Aqaba International Dive Center added');
    } catch (e) {
      setState(() => _businessStatus = 'ERROR: $e');
    } finally {
      setState(() => _isAddingBusiness = false);
    }
  }

  Future<void> _addNewChallenges() async {
    setState(() {
      _isAddingChallenges = true;
      _challengesStatus = 'Adding...';
    });
    try {
      await ChallengeSeedService().addChallenges([
        Challenge(
          id: 'hunt_royal_botanic_1',
          destinationId: 'royal_botanic_garden',
          destinationName: 'Royal Botanic Garden',
          title: 'Native Plant Detective',
          description: 'Find and photograph the garden\'s collection of native Jordanian plants.',
          latitude: 32.183365,
          longitude: 35.828026,
          rewardCoins: 15,
          badgeName: 'Botanist',
          difficulty: 'Easy',
        ),
        Challenge(
          id: 'hunt_royal_botanic_2',
          destinationId: 'royal_botanic_garden',
          destinationName: 'Royal Botanic Garden',
          title: 'Trail to the Hills',
          description: 'Follow a walking trail up into the hills of Tal Al-Roman for a sweeping view over the garden.',
          latitude: 32.183365,
          longitude: 35.828026,
          rewardCoins: 22,
          badgeName: 'Trailblazer',
          difficulty: 'Medium',
        ),
        Challenge(
          id: 'hunt_main_1',
          destinationId: 'main_hot_springs',
          destinationName: "Ma'in Hot Springs",
          title: 'Waterfall Warmth',
          description: 'Photograph yourself beneath one of the cascading hot mineral waterfalls.',
          latitude: 31.609444,
          longitude: 35.610278,
          rewardCoins: 15,
          badgeName: 'Spring Seeker',
          difficulty: 'Easy',
        ),
        Challenge(
          id: 'hunt_main_2',
          destinationId: 'main_hot_springs',
          destinationName: "Ma'in Hot Springs",
          title: 'Steam Seeker',
          description: 'Track down the hottest of the mineral pools cascading down the cliffs.',
          latitude: 31.609444,
          longitude: 35.610278,
          rewardCoins: 24,
          badgeName: 'Heat Chaser',
          difficulty: 'Medium',
        ),
        Challenge(
          id: 'hunt_azraq_1',
          destinationId: 'azraq_wetland_reserve',
          destinationName: 'Azraq Wetland Reserve',
          title: "Birdwatcher's Eye",
          description: 'Spot and photograph one of the hundreds of migratory bird species passing through the reserve.',
          latitude: 31.83377,
          longitude: 36.82129,
          rewardCoins: 15,
          badgeName: 'Migration Watcher',
          difficulty: 'Easy',
        ),
        Challenge(
          id: 'hunt_azraq_2',
          destinationId: 'azraq_wetland_reserve',
          destinationName: 'Azraq Wetland Reserve',
          title: 'The Sirhan Fish Hunt',
          description: 'Find the pool that\'s home to the Sirhan fish, Jordan\'s only endemic vertebrate species.',
          latitude: 31.83377,
          longitude: 36.82129,
          rewardCoins: 38,
          badgeName: 'Endemic Explorer',
          difficulty: 'Hard',
        ),
        Challenge(
          id: 'hunt_madaba_1',
          destinationId: 'madaba_archaeological_park',
          destinationName: 'Madaba Archaeological Park',
          title: 'The Oldest Mosaic',
          description: 'Find the oldest mosaic fragment ever discovered in Jordan, on display right at the entrance.',
          latitude: 31.716107,
          longitude: 35.79548,
          rewardCoins: 15,
          badgeName: 'Mosaic Hunter',
          difficulty: 'Easy',
        ),
        Challenge(
          id: 'hunt_madaba_2',
          destinationId: 'madaba_archaeological_park',
          destinationName: 'Madaba Archaeological Park',
          title: 'Hippolytus Hall',
          description: 'Find the 6th-century mosaic floor depicting the ancient myth of Hippolytus.',
          latitude: 31.716107,
          longitude: 35.79548,
          rewardCoins: 26,
          badgeName: 'Myth Seeker',
          difficulty: 'Medium',
        ),
        Challenge(
          id: 'hunt_wadi_mujib_1',
          destinationId: 'wadi_mujib',
          destinationName: 'Wadi Mujib',
          title: 'Cross the Dam',
          description: 'Cross the signature steel walkway spanning the Mujib Dam for your first view into the gorge.',
          latitude: 31.49278,
          longitude: 35.605,
          rewardCoins: 18,
          badgeName: 'Canyon Crosser',
          difficulty: 'Easy',
        ),
        Challenge(
          id: 'hunt_wadi_mujib_2',
          destinationId: 'wadi_mujib',
          destinationName: 'Wadi Mujib',
          title: 'Into the Siq',
          description: 'Step into the narrow sandstone slot canyon at the mouth of the gorge — the start of Jordan\'s most thrilling canyoning trail.',
          latitude: 31.49278,
          longitude: 35.605,
          rewardCoins: 40,
          badgeName: 'Canyoneer',
          difficulty: 'Hard',
        ),
        Challenge(
          id: 'hunt_aqaba_marine_1',
          destinationId: 'aqaba_marine_reserve',
          destinationName: 'Aqaba Marine Reserve',
          title: 'Blue Flag Beach',
          description: 'Reach the Blue Flag-certified Blue Beach, recognized for its water quality and cleanliness.',
          latitude: 29.4700,
          longitude: 35.0000,
          radiusMeters: 400,
          rewardCoins: 18,
          badgeName: 'Blue Flag Finder',
          difficulty: 'Easy',
        ),
        Challenge(
          id: 'hunt_aqaba_marine_2',
          destinationId: 'aqaba_marine_reserve',
          destinationName: 'Aqaba Marine Reserve',
          title: 'Underwater Museum',
          description: 'Find the Military Diving Museum at Yamaninya Beach — the first military underwater museum in the region.',
          latitude: 29.4700,
          longitude: 35.0000,
          radiusMeters: 400,
          rewardCoins: 28,
          badgeName: 'Museum Diver',
          difficulty: 'Medium',
        ),
      ]);
      setState(() => _challengesStatus = '✅ 12 new challenges added');
    } catch (e) {
      setState(() => _challengesStatus = 'ERROR: $e');
    } finally {
      setState(() => _isAddingChallenges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Destinations (Dev Only)')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                '⚠️ Overwrites ALL 10 built-in destinations back to their code-defined state',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSeeding ? null : _runSeed,
                child: _isSeeding
                    ? const CircularProgressIndicator(color: AppColors.background)
                    : const Text('Seed Firestore Now (full batch)'),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                'Add one new destination — safe, only writes this one doc',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(_singleStatus, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isAddingSingle ? null : _addSingleDestination,
                child: _isAddingSingle
                    ? const CircularProgressIndicator(color: AppColors.background)
                    : const Text('Add Royal Botanic Garden'),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                'Add one new business — safe, only writes this one doc',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(_businessStatus, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isAddingBusiness ? null : _addSingleBusiness,
                child: _isAddingBusiness
                    ? const CircularProgressIndicator(color: AppColors.background)
                    : const Text('Add Aqaba Dive Center'),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                'Add 12 new challenges for the 6 new destinations — safe, only writes these ids',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(_challengesStatus, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isAddingChallenges ? null : _addNewChallenges,
                child: _isAddingChallenges
                    ? const CircularProgressIndicator(color: AppColors.background)
                    : const Text('Add New Challenges'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}