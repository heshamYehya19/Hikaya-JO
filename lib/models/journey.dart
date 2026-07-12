class JourneyStop {
  final String destinationId;
  final String destinationName;
  final String suggestedTime;
  final int durationMinutes;
  final double estimatedCost;
  final String notes;

  JourneyStop({
    required this.destinationId,
    required this.destinationName,
    required this.suggestedTime,
    required this.durationMinutes,
    required this.estimatedCost,
    required this.notes,
  });

  factory JourneyStop.fromMap(Map<String, dynamic> map) {
    return JourneyStop(
      destinationId: map['destinationId'] ?? '',
      destinationName: map['destinationName'] ?? '',
      suggestedTime: map['suggestedTime'] ?? '',
      durationMinutes: (map['durationMinutes'] ?? 60) is int
          ? map['durationMinutes']
          : int.tryParse('${map['durationMinutes']}') ?? 60,
      estimatedCost: (map['estimatedCost'] ?? 0).toDouble(),
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'destinationId': destinationId,
    'destinationName': destinationName,
    'suggestedTime': suggestedTime,
    'durationMinutes': durationMinutes,
    'estimatedCost': estimatedCost,
    'notes': notes,
  };
}

class Journey {
  final String id;
  final List<JourneyStop> stops;
  final int totalDurationMinutes;
  final double totalCost;
  final DateTime createdAt;

  Journey({
    required this.id,
    required this.stops,
    required this.totalDurationMinutes,
    required this.totalCost,
    required this.createdAt,
  });
}