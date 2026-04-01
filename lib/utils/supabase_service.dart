import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tacit_understanding/config.dart';
import 'package:tacit_understanding/models/room.dart';
import 'package:tacit_understanding/models/player.dart';
import 'package:tacit_understanding/models/game_session.dart';
import 'package:tacit_understanding/providers/game_provider.dart';
import 'dart:async';
import 'dart:math';

class SupabaseService {
  final supabase = Supabase.instance.client;
  
  // 保存监听器引用
  Map<String, StreamSubscription> _subscriptions = {};

  // 生成6位房间号
  String _generateRoomCode() {
    const chars = '0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(Config.roomCodeLength, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // 创建房间
  Future<Room> createRoom({
    required GameMode gameMode,
    required int maxPlayers,
    required int rounds,
    required int drawingTime,
  }) async {
    String roomCode;
    bool codeExists;
    int attempts = 0;

    do {
      roomCode = _generateRoomCode();
      final existingRooms = await supabase
          .from('rooms')
          .select('id')
          .eq('code', roomCode)
          .eq('status', 'waiting')
          .limit(1);
      codeExists = existingRooms.isNotEmpty;
      attempts++;
    } while (codeExists && attempts < Config.roomCodeMaxAttempts);

    if (codeExists) {
      throw Exception('无法生成唯一房间号');
    }

    final response = await supabase.from('rooms').insert({
      'code': roomCode,
      'game_mode': gameMode == GameMode.questionAnswer ? 'question_answer' : 'draw_and_guess',
      'status': 'waiting',
      'max_players': maxPlayers,
      'rounds': rounds,
      'drawing_time': drawingTime,
    }).select();

    final roomData = response[0];
    return Room(
      id: roomData['id'],
      code: roomData['code'],
      gameMode: gameMode,
      status: RoomStatus.waiting,
      maxPlayers: roomData['max_players'],
      rounds: roomData['rounds'],
      drawingTime: roomData['drawing_time'],
      hostId: '', // 稍后设置
      players: [],
      createdAt: DateTime.parse(roomData['created_at']),
    );
  }

  // 加入房间
  Future<Player> joinRoom({
    required String roomId,
    required String playerName,
    required bool isHost,
  }) async {
    // 检查是否已经有同名玩家在该房间中且未离开
    final existingPlayers = await supabase
        .from('players')
        .select()
        .eq('room_id', roomId)
        .eq('name', playerName)
        .filter('left_at', 'is', null);
    
    if (existingPlayers.isNotEmpty) {
      throw Exception('该昵称已被使用，请选择其他昵称');
    }
    
    // 检查是否有同名的已离开玩家，如果有则更新为重新加入
    final leftPlayers = await supabase
        .from('players')
        .select()
        .eq('room_id', roomId)
        .eq('name', playerName)
        .filter('left_at', 'not.is', null);
    
    if (leftPlayers.isNotEmpty) {
      // 重新激活已离开的玩家
      final playerId = leftPlayers[0]['id'];
      await supabase
          .from('players')
          .update({
            'left_at': null,
            'joined_at': DateTime.now().toIso8601String(),
            'is_host': isHost,
          })
          .eq('id', playerId);
      
      // 返回更新后的玩家信息
      final updatedPlayer = await supabase
          .from('players')
          .select()
          .eq('id', playerId)
          .single();
      
      return Player(
        id: updatedPlayer['id'],
        roomId: updatedPlayer['room_id'],
        name: updatedPlayer['name'],
        isHost: updatedPlayer['is_host'],
        score: updatedPlayer['score'] ?? 0,
        joinedAt: DateTime.parse(updatedPlayer['joined_at']),
        leftAt: null,
      );
    }
    
    final response = await supabase.from('players').insert({
      'room_id': roomId,
      'name': playerName,
      'is_host': isHost,
      'score': 0,
    }).select();

    final playerData = response[0];
    final player = Player(
      id: playerData['id'],
      roomId: playerData['room_id'],
      name: playerData['name'],
      isHost: playerData['is_host'],
      score: playerData['score'],
      joinedAt: DateTime.parse(playerData['joined_at']),
    );

    // 如果是房主，更新房间的host_id
    if (isHost) {
      await supabase
          .from('rooms')
          .update({'host_id': player.id})
          .eq('id', roomId)
          .select();
    }

    return player;
  }

  // 根据房间号获取房间
  Future<Room?> getRoomByCode(String code) async {
    final response = await supabase
        .from('rooms')
        .select('*, players(*)')
        .eq('code', code)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    final roomData = response[0];
    final players = (roomData['players'] as List<dynamic>)
        .map((p) => Player.fromJson(p))
        .toList();

    return Room(
      id: roomData['id'],
      code: roomData['code'],
      gameMode: roomData['game_mode'] == 'question_answer' ? GameMode.questionAnswer : GameMode.drawAndGuess,
      status: RoomStatus.values.firstWhere((s) => _getStatusToString(s) == roomData['status']),
      maxPlayers: roomData['max_players'],
      rounds: roomData['rounds'],
      drawingTime: roomData['drawing_time'],
      hostId: roomData['host_id'],
      players: players,
      createdAt: DateTime.parse(roomData['created_at']),
      updatedAt: roomData['updated_at'] != null ? DateTime.parse(roomData['updated_at']) : null,
    );
  }

  // 开始游戏
  Future<void> startGame(String roomId) async {
    // 更新房间状态
    await supabase
        .from('rooms')
        .update({'status': 'playing'})
        .eq('id', roomId)
        .select();

    // 创建游戏会话
    await supabase.from('game_sessions').insert({
      'room_id': roomId,
      'current_round': 1,
      'answers': {},
      'guesses': {},
      'drawing_actions': [],
    }).select();
  }

  // 监听玩家变化 - 使用轮询机制确保可靠性
  Timer? _playerPollTimer;
  
  void listenToPlayers(String roomId, Function(List<Player>) callback) {
    // 取消之前的订阅和定时器
    final playerKey = 'players_$roomId';
    if (_subscriptions.containsKey(playerKey)) {
      _subscriptions[playerKey]?.cancel();
    }
    _playerPollTimer?.cancel();
    
    // 首先立即获取一次数据
    getPlayers(roomId).then((players) {
      print('Initial player load: ${players.length} players');
      callback(players);
    });
    
    // 尝试使用实时流（如果Supabase实时功能可用）
    try {
      final subscription = supabase
          .from('players')
          .stream(primaryKey: ['id'])
          .eq('room_id', roomId)
          .order('joined_at', ascending: true)
          .listen((data) {
        print('Stream received player updates: ${data.length} players');
        final players = data.map((e) => Player.fromJson(e)).where((p) => p.leftAt == null).toList();
        print('Stream filtered players: ${players.map((p) => p.name).toList()}');
        callback(players);
      }, onError: (error) {
        print('Error in player stream: $error');
      });
      
      _subscriptions[playerKey] = subscription;
    } catch (e) {
      print('Failed to setup player stream: $e');
    }
    
    // 设置轮询作为备用机制（每3秒刷新一次）
    _playerPollTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      try {
        final players = await getPlayers(roomId);
        print('Poll refresh: ${players.length} players');
        callback(players);
      } catch (e) {
        print('Error in player poll: $e');
      }
    });
  }
  
  // 停止玩家监听
  void stopListeningToPlayers() {
    _playerPollTimer?.cancel();
    _playerPollTimer = null;
  }

  // 监听游戏会话变化
  void listenToGameSession(String roomId, Function(GameSession) callback) {
    // 取消之前的订阅
    final sessionKey = 'session_$roomId';
    if (_subscriptions.containsKey(sessionKey)) {
      _subscriptions[sessionKey]?.cancel();
    }
    
    final subscription = supabase
        .from('game_sessions')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(1)
        .listen((data) {
      if (data.isNotEmpty) {
        callback(GameSession.fromJson(data.first));
      }
    });
    
    // 保存订阅引用
    _subscriptions[sessionKey] = subscription;
  }

  // 获取玩家列表
  Future<List<Player>> getPlayers(String roomId) async {
    final response = await supabase
        .from('players')
        .select()
        .eq('room_id', roomId);

    return (response as List<dynamic>)
        .map((p) => Player.fromJson(p))
        .where((player) => player.leftAt == null)
        .toList();
  }

  // 获取游戏会话
  Future<GameSession?> _getGameSession(String roomId) async {
    final response = await supabase
        .from('game_sessions')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return GameSession.fromJson(response[0]);
  }

  // 离开房间
  Future<void> leaveRoom({
    required String roomId,
    required String playerId,
  }) async {
    await supabase
        .from('players')
        .update({'left_at': DateTime.now().toIso8601String()})
        .eq('id', playerId)
        .select();
  }

  // 提交答案
  Future<void> submitAnswer({
    required String roomId,
    required String playerId,
    required String answer,
  }) async {
    final session = await _getGameSession(roomId);
    if (session == null) return;

    final updatedAnswers = Map<String, String>.from(session.answers);
    updatedAnswers[playerId] = answer;

    await supabase
        .from('game_sessions')
        .update({'answers': updatedAnswers})
        .eq('id', session.id)
        .select();
  }

  // 提交猜词
  Future<void> submitGuess({
    required String roomId,
    required String playerId,
    required String guess,
  }) async {
    final session = await _getGameSession(roomId);
    if (session == null) return;

    final updatedGuesses = Map<String, String>.from(session.guesses);
    if (!updatedGuesses.containsKey(playerId)) {
      updatedGuesses[playerId] = guess;

      await supabase
          .from('game_sessions')
          .update({'guesses': updatedGuesses})
          .eq('id', session.id)
          .select();
    }
  }

  // 发送作画动作
  Future<void> sendDrawingAction({
    required String roomId,
    required DrawingAction action,
  }) async {
    final session = await _getGameSession(roomId);
    if (session == null) return;

    final updatedActions = List<DrawingAction>.from(session.drawingActions);
    updatedActions.add(action);

    await supabase
        .from('game_sessions')
        .update({
          'drawing_actions': updatedActions.map((a) => a.toJson()).toList(),
        })
        .eq('id', session.id)
        .select();
  }

  // 获取状态字符串
  String _getStatusToString(RoomStatus status) {
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
  
  // 取消所有订阅
  void cancelAllSubscriptions() {
    _subscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    _subscriptions.clear();
  }
  
  // 取消特定房间的订阅
  void cancelRoomSubscriptions(String roomId) {
    final keys = _subscriptions.keys.where((key) => key.contains(roomId)).toList();
    for (final key in keys) {
      _subscriptions[key]?.cancel();
      _subscriptions.remove(key);
    }
    // 停止轮询定时器
    stopListeningToPlayers();
  }
  
  // 清理过期房间（超过10分钟未开始游戏的waiting状态房间）
  Future<void> cleanupExpiredRooms() async {
    try {
      final timeoutMinutes = 10;
      final cutoffTime = DateTime.now().subtract(Duration(minutes: timeoutMinutes));
      
      // 获取所有过期的waiting状态房间
      final expiredRooms = await supabase
          .from('rooms')
          .select('id')
          .eq('status', 'waiting')
          .lt('created_at', cutoffTime.toIso8601String());
      
      if (expiredRooms.isNotEmpty) {
        print('Found ${expiredRooms.length} expired rooms to cleanup');
        
        for (final room in expiredRooms) {
          final roomId = room['id'];
          
          // 标记房间为ended状态
          await supabase
              .from('rooms')
              .update({'status': 'ended'})
              .eq('id', roomId);
          
          // 标记房间内的所有玩家为已离开
          await supabase
              .from('players')
              .update({'left_at': DateTime.now().toIso8601String()})
              .eq('room_id', roomId)
              .filter('left_at', 'is', null);
        }
        
        print('Cleanup completed: ${expiredRooms.length} rooms processed');
      }
    } catch (e) {
      print('Error during room cleanup: $e');
    }
  }
}
