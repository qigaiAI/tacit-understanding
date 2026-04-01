import 'package:tacit_understanding/providers/game_provider.dart';
import 'package:tacit_understanding/models/player.dart';

class Room {
  final String id;
  final String code;
  final GameMode gameMode;
  final RoomStatus status;
  final int maxPlayers;
  final int rounds;
  final int drawingTime;
  final String hostId;
  final List<Player> players;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Room({
    required this.id,
    required this.code,
    required this.gameMode,
    required this.status,
    required this.maxPlayers,
    required this.rounds,
    required this.drawingTime,
    required this.hostId,
    required this.players,
    required this.createdAt,
    this.updatedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      code: json['code'],
      gameMode: json['game_mode'] == 'question_answer' ? GameMode.questionAnswer : GameMode.drawAndGuess,
      status: _getStatusFromJson(json['status']),
      maxPlayers: json['max_players'],
      rounds: json['rounds'],
      drawingTime: json['drawing_time'],
      hostId: json['host_id'],
      players: (json['players'] as List<dynamic>?)?.map((p) => Player.fromJson(p)).toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'game_mode': gameMode == GameMode.questionAnswer ? 'question_answer' : 'draw_and_guess',
      'status': _getStatusToString(status),
      'max_players': maxPlayers,
      'rounds': rounds,
      'drawing_time': drawingTime,
      'host_id': hostId,
      'players': players.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static RoomStatus _getStatusFromJson(String status) {
    switch (status) {
      case 'waiting':
        return RoomStatus.waiting;
      case 'playing':
        return RoomStatus.playing;
      case 'ended':
        return RoomStatus.ended;
      default:
        return RoomStatus.waiting;
    }
  }

  static String _getStatusToString(RoomStatus status) {
    switch (status) {
      case RoomStatus.waiting:
        return 'waiting';
      case RoomStatus.playing:
        return 'playing';
      case RoomStatus.ended:
        return 'ended';
      default:
        return 'waiting';
    }
  }
}
