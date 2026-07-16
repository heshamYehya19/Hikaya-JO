import 'package:cloud_firestore/cloud_firestore.dart';

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
  factory Journey.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate(); // handles old Firestore docs saved before this fix
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return Journey(
      id: id,
      stops: (map['stops'] as List)
          .map((s) => JourneyStop.fromMap(s as Map<String, dynamic>))
          .toList(),
      totalDurationMinutes: map['totalDurationMinutes'] ?? 0,
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'stops': stops.map((s) => s.toMap()).toList(),
    'totalDurationMinutes': totalDurationMinutes,
    'totalCost': totalCost,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  Journey({
    required this.id,
    required this.stops,
    required this.totalDurationMinutes,
    required this.totalCost,
    required this.createdAt,
  });
}