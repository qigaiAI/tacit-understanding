class Player {
  final String id;
  final String roomId;
  final String name;
  final bool isHost;
  final int score;
  final DateTime joinedAt;
  final DateTime? leftAt;

  Player({
    required this.id,
    required this.roomId,
    required this.name,
    required this.isHost,
    required this.score,
    required this.joinedAt,
    this.leftAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      roomId: json['room_id'],
      name: json['name'],
      isHost: json['is_host'],
      score: json['score'] ?? 0,
      joinedAt: DateTime.parse(json['joined_at']),
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'name': name,
      'is_host': isHost,
      'score': score,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
    };
  }

  Player copyWith({int? score}) {
    return Player(
      id: id,
      roomId: roomId,
      name: name,
      isHost: isHost,
      score: score ?? this.score,
      joinedAt: joinedAt,
      leftAt: leftAt,
    );
  }
}
