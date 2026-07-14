class Business {
  final String id;
  final String name;
  final String type; // restaurant, guide, artisan, shop
  final String destinationId; // which destination this business is near
  final String description;
  final String offer; // e.g. "10% off with Hikaya JO"
  final int coinsRequired; // cost to redeem the offer
  final String contactInfo;
  final bool verified;

  Business({
    required this.id,
    required this.name,
    required this.type,
    required this.destinationId,
    required this.description,
    required this.offer,
    this.coinsRequired = 20,
    this.contactInfo = '',
    this.verified = true,
  });

  factory Business.fromMap(String id, Map<String, dynamic> map) {
    return Business(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'shop',
      destinationId: map['destinationId'] ?? '',
      description: map['description'] ?? '',
      offer: map['offer'] ?? '',
      coinsRequired: map['coinsRequired'] ?? 20,
      contactInfo: map['contactInfo'] ?? '',
      verified: map['verified'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'destinationId': destinationId,
    'description': description,
    'offer': offer,
    'coinsRequired': coinsRequired,
    'contactInfo': contactInfo,
    'verified': verified,
  };
}