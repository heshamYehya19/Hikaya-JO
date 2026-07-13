class Challenge {
  final String id;
  final String destinationId;
  final String destinationName;
  final String title;
  final String description;
  final int rewardCoins;
  final String badgeName;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  Challenge({
    required this.id,
    required this.destinationId,
    required this.destinationName,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.rewardCoins = 15,
    this.badgeName = 'Explorer',
    this.radiusMeters = 150,
  });

  factory Challenge.fromMap(String id, Map<String, dynamic> map) {
    return Challenge(
      id: id,
      destinationId: map['destinationId'] ?? '',
      destinationName: map['destinationName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      rewardCoins: map['rewardCoins'] ?? 15,
      badgeName: map['badgeName'] ?? 'Explorer',
      radiusMeters: (map['radiusMeters'] ?? 150).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'destinationId': destinationId,
    'destinationName': destinationName,
    'title': title,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'rewardCoins': rewardCoins,
    'badgeName': badgeName,
    'radiusMeters': radiusMeters,
  };
}