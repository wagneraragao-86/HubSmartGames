import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Score {
  final String id;
  final String playerId;
  final String playerName;
  final String gameId;
  final int points;
  final DateTime date;
  final int? duration; // em segundos
  final Map<String, dynamic>? metadata;

  Score({
    String? id,
    required this.playerId,
    required this.playerName,
    required this.gameId,
    required this.points,
    DateTime? date,
    this.duration,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Duration get durationDuration => Duration(seconds: duration ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'playerName': playerName,
      'gameId': gameId,
      'points': points,
      'date': date.toIso8601String(),
      'duration': duration,
      'metadata': metadata,
    };
  }

  factory Score.fromMap(Map<dynamic, dynamic> map) {
    final dateValue = map['date'] ?? map['timestamp'];
    return Score(
      id: map['id']?.toString(),
      playerId: map['playerId']?.toString() ?? '',
      playerName: map['playerName']?.toString() ?? 'Unknown',
      gameId: map['gameId']?.toString() ?? '',
      points: (map['points'] is int ? map['points'] : int.tryParse(map['points']?.toString() ?? '0')) ?? 0,
      date: _parseDate(dateValue),
      duration: map['duration'] is int ? map['duration'] as int? : int.tryParse(map['duration']?.toString() ?? ''),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    } else if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is Map && value.containsKey('_seconds') && value.containsKey('_nanoseconds')) {
      final seconds = value['_seconds'] as int? ?? 0;
      final nanoseconds = value['_nanoseconds'] as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + nanoseconds ~/ 1000000);
    } else {
      return DateTime.now();
    }
  }

  Score copyWith({
    String? id,
    String? playerId,
    String? playerName,
    String? gameId,
    int? points,
    DateTime? date,
    int? duration,
    Map<String, dynamic>? metadata,
  }) {
    return Score(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      gameId: gameId ?? this.gameId,
      points: points ?? this.points,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
    );
  }
}
