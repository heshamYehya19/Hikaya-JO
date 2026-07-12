class Destination {
  final String id;
  final String name;
  final String type; // historical, natural, cultural
  final double latitude;
  final double longitude;
  final String description;
  final bool isLesserKnown;
  final List<String> imageUrls;
  final int avgVisitMinutes;
  final String costLevel; // free, low, medium, high

  Destination({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.isLesserKnown = false,
    this.imageUrls = const [],
    this.avgVisitMinutes = 90,
    this.costLevel = 'medium',
  });

  factory Destination.fromMap(String id, Map<String, dynamic> map) {
    return Destination(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'cultural',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      description: map['description'] ?? '',
      isLesserKnown: map['isLesserKnown'] ?? false,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      avgVisitMinutes: map['avgVisitMinutes'] ?? 90,
      costLevel: map['costLevel'] ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'isLesserKnown': isLesserKnown,
      'imageUrls': imageUrls,
      'avgVisitMinutes': avgVisitMinutes,
      'costLevel': costLevel,
    };
  }
}