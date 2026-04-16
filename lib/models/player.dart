import 'package:uuid/uuid.dart';

class Player {
  final String id;
  final String name;
  final String? avatar;
  final DateTime createdAt;
  final List<String> friendIds;

  Player({
    String? id,
    required this.name,
    this.avatar,
    DateTime? createdAt,
    List<String>? friendIds,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        friendIds = friendIds ?? [];

  Player copyWith({
    String? id,
    String? name,
    String? avatar,
    DateTime? createdAt,
    List<String>? friendIds,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      friendIds: friendIds ?? this.friendIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'friendIds': friendIds,
    };
  }

  factory Player.fromMap(Map<dynamic, dynamic> map) {
    return Player(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      avatar: map['avatar'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      friendIds: List<String>.from(map['friendIds'] as List? ?? []),
    );
  }
}
