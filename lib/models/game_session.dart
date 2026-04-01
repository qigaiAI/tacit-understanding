import 'package:tacit_understanding/providers/game_provider.dart';
import 'package:tacit_understanding/models/player.dart';

class GameSession {
  final String id;
  final String roomId;
  final GameMode gameMode;
  final int currentRound;
  final String? currentQuestion;
  final String? currentWord;
  final String? drawerId;
  final String? questionerId;
  final Map<String, String> answers;
  final Map<String, String> guesses;
  final List<DrawingAction> drawingActions;
  final DateTime startedAt;
  final DateTime? endedAt;

  GameSession({
    required this.id,
    required this.roomId,
    required this.gameMode,
    required this.currentRound,
    this.currentQuestion,
    this.currentWord,
    this.drawerId,
    this.questionerId,
    required this.answers,
    required this.guesses,
    required this.drawingActions,
    required this.startedAt,
    this.endedAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'],
      roomId: json['room_id'],
      gameMode: json['game_mode'] == 'question_answer' ? GameMode.questionAnswer : GameMode.drawAndGuess,
      currentRound: json['current_round'],
      currentQuestion: json['current_question'],
      currentWord: json['current_word'],
      drawerId: json['drawer_id'],
      questionerId: json['questioner_id'],
      answers: Map<String, String>.from(json['answers'] ?? {}),
      guesses: Map<String, String>.from(json['guesses'] ?? {}),
      drawingActions: (json['drawing_actions'] as List<dynamic>?)?.map((a) => DrawingAction.fromJson(a)).toList() ?? [],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'game_mode': gameMode == GameMode.questionAnswer ? 'question_answer' : 'draw_and_guess',
      'current_round': currentRound,
      'current_question': currentQuestion,
      'current_word': currentWord,
      'drawer_id': drawerId,
      'questioner_id': questionerId,
      'answers': answers,
      'guesses': guesses,
      'drawing_actions': drawingActions.map((a) => a.toJson()).toList(),
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }
}

class DrawingAction {
  final String type; // 'draw', 'erase', 'clear', 'undo', 'redo'
  final List<DrawingOffset>? points;
  final DateTime timestamp;

  DrawingAction({
    required this.type,
    this.points,
    required this.timestamp,
  });

  factory DrawingAction.fromJson(Map<String, dynamic> json) {
    return DrawingAction(
      type: json['type'],
      points: (json['points'] as List<dynamic>?)?.map((p) => DrawingOffset(p[0], p[1])).toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'points': points?.map((p) => [p.dx, p.dy]).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DrawingOffset {
  final double dx;
  final double dy;

  DrawingOffset(this.dx, this.dy);
}
