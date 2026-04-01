import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tacit_understanding/models/room.dart';
import 'package:tacit_understanding/models/player.dart';
import 'package:tacit_understanding/models/game_session.dart';
import 'package:tacit_understanding/utils/supabase_service.dart';
import 'dart:convert';

class GameProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  late SharedPreferences _prefs;
  
  // 状态
  Room? _currentRoom;
  Player? _currentPlayer;
  GameSession? _currentSession;
  List<Player> _players = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // 游戏状态
  GameMode _gameMode = GameMode.questionAnswer;
  int _maxPlayers = 4;
  int _rounds = 3;
  int _drawingTime = 80;
  
  // 题库和词库
  List<String> _presetQuestions = [];
  List<String> _drawGuessWords = [];
  bool _isDataLoaded = false;
  
  // Getters
  Room? get currentRoom => _currentRoom;
  Player? get currentPlayer => _currentPlayer;
  GameSession? get currentSession => _currentSession;
  List<Player> get players => _players;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GameMode get gameMode => _gameMode;
  int get maxPlayers => _maxPlayers;
  int get rounds => _rounds;
  int get drawingTime => _drawingTime;
  List<String> get presetQuestions => _presetQuestions;
  List<String> get drawGuessWords => _drawGuessWords;
  
  // 初始化
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await loadPresetData();
    await loadSavedState();
    
    // 清理过期房间
    await _supabaseService.cleanupExpiredRooms();
    
    _isInitialized = true;
  }

  // 加载预设数据
  Future<void> loadPresetData() async {
    if (_isDataLoaded) return;
    
    try {
      // 加载预设题库
      final questionsJson = await rootBundle.loadString('assets/data/preset_questions.json');
      final questionsData = json.decode(questionsJson);
      _presetQuestions = List<String>.from(questionsData['questions']);
      
      // 加载你画我猜词库
      final wordsJson = await rootBundle.loadString('assets/data/draw_guess_words.json');
      final wordsData = json.decode(wordsJson);
      _drawGuessWords = List<String>.from(wordsData['words']);
      
      _isDataLoaded = true;
    } catch (e) {
      // 如果加载失败，使用默认数据
      _presetQuestions = [
        '我最喜欢的颜色',
        '我的生日月份',
        '我最喜欢的食物',
        '我最喜欢的电影',
        '我的幸运数字',
        '我最喜欢的动物',
        '我最喜欢的季节',
        '我最喜欢的运动',
        '我的星座',
        '我最喜欢的音乐类型',
      ];
      
      _drawGuessWords = [
        '苹果', '香蕉', '猫', '狗', '飞机', '汽车', '足球', '篮球',
        '电脑', '手机', '雨伞', '帽子', '鞋子', '衣服', '书本', '铅笔',
      ];
    }
  }

  // 加载保存的状态
  Future<void> loadSavedState() async {
    final roomJson = _prefs.getString('currentRoom');
    final playerJson = _prefs.getString('currentPlayer');
    
    if (roomJson != null && playerJson != null) {
      try {
        _currentRoom = Room.fromJson(json.decode(roomJson));
        _currentPlayer = Player.fromJson(json.decode(playerJson));
        
        // 重新设置监听器
        _setupRoomListeners();
        
        // 重新获取玩家列表
        if (_currentRoom != null) {
          final players = await _supabaseService.getPlayers(_currentRoom!.id);
          _players = players;
        }
        
        notifyListeners();
      } catch (e) {
        print('加载保存的状态失败: $e');
      }
    }
  }

  // 保存状态
  Future<void> saveState() async {
    if (_currentRoom != null) {
      _prefs.setString('currentRoom', json.encode(_currentRoom!.toJson()));
    }
    if (_currentPlayer != null) {
      _prefs.setString('currentPlayer', json.encode(_currentPlayer!.toJson()));
    }
  }

  // 清除保存的状态
  Future<void> clearSavedState() async {
    _prefs.remove('currentRoom');
    _prefs.remove('currentPlayer');
  }
  
  // Setters
  set gameMode(GameMode mode) {
    _gameMode = mode;
    notifyListeners();
  }
  
  set maxPlayers(int value) {
    _maxPlayers = value;
    notifyListeners();
  }
  
  set rounds(int value) {
    _rounds = value;
    notifyListeners();
  }
  
  set drawingTime(int value) {
    _drawingTime = value;
    notifyListeners();
  }
  
  // 清空状态
  void resetState() {
    _currentRoom = null;
    _currentPlayer = null;
    _currentSession = null;
    _players = [];
    _errorMessage = null;
    notifyListeners();
  }
  
  // 创建房间
  Future<bool> createRoom(String playerName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final room = await _supabaseService.createRoom(
        gameMode: _gameMode,
        maxPlayers: _maxPlayers,
        rounds: _rounds,
        drawingTime: _drawingTime,
      );
      
      final player = await _supabaseService.joinRoom(
        roomId: room.id,
        playerName: playerName,
        isHost: true,
      );
      
      _currentRoom = room;
      _currentPlayer = player;
      
      // 重新获取最新的玩家列表，确保数据准确
      final updatedPlayers = await _supabaseService.getPlayers(room.id);
      _players = updatedPlayers;
      print('Initial players after creating room: ${_players.length} players');
      
      // 监听房间变化
      _setupRoomListeners();
      
      // 保存状态
      await saveState();
      
      return true;
    } catch (e) {
      _errorMessage = '创建房间失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 加入房间
  Future<bool> joinRoom(String roomCode, String playerName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final room = await _supabaseService.getRoomByCode(roomCode);
      if (room == null) {
        _errorMessage = '房间不存在';
        return false;
      }
      
      if (room.status == RoomStatus.playing) {
        _errorMessage = '游戏已开始，无法加入';
        return false;
      }
      
      if (room.players.length >= room.maxPlayers) {
        _errorMessage = '房间已满';
        return false;
      }
      
      final player = await _supabaseService.joinRoom(
        roomId: room.id,
        playerName: playerName,
        isHost: false,
      );
      
      _currentRoom = room;
      _currentPlayer = player;
      
      // 重新获取最新的玩家列表，确保包含刚加入的玩家
      final updatedPlayers = await _supabaseService.getPlayers(room.id);
      _players = updatedPlayers;
      print('Initial players after joining: ${_players.length} players');
      
      // 监听房间变化
      _setupRoomListeners();
      
      // 保存状态
      await saveState();
      
      return true;
    } catch (e) {
      _errorMessage = '加入房间失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 开始游戏
  Future<bool> startGame() async {
    if (_currentRoom == null || !_currentPlayer!.isHost) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _supabaseService.startGame(_currentRoom!.id);
      return true;
    } catch (e) {
      _errorMessage = '开始游戏失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 监听房间变化
  void _setupRoomListeners() {
    if (_currentRoom == null) return;
    
    print('Setting up listeners for room: ${_currentRoom!.id}');
    
    // 监听玩家变化
    _supabaseService.listenToPlayers(_currentRoom!.id, (players) {
      print('Updating players: ${players.length} players');
      _players = players;
      notifyListeners();
    });
    
    // 监听游戏状态变化
    _supabaseService.listenToGameSession(_currentRoom!.id, (session) {
      _currentSession = session;
      notifyListeners();
    });
    
    // 再次获取最新的玩家列表，确保本地状态与数据库同步
    // 解决监听器生效延迟的问题
    _supabaseService.getPlayers(_currentRoom!.id).then((players) {
      print('Refreshing players after setting up listeners: ${players.length} players');
      _players = players;
      notifyListeners();
    });
  }
  
  // 离开房间
  Future<void> leaveRoom() async {
    if (_currentRoom == null || _currentPlayer == null) return;
    
    try {
      await _supabaseService.leaveRoom(
        roomId: _currentRoom!.id,
        playerId: _currentPlayer!.id,
      );
      
      // 取消房间订阅
      _supabaseService.cancelRoomSubscriptions(_currentRoom!.id);
      
      // 清除保存的状态
      await clearSavedState();
      
      resetState();
    } catch (e) {
      _errorMessage = '离开房间失败: $e';
      notifyListeners();
    }
  }
  
  // 提交答案（默契问答）
  Future<void> submitAnswer(String answer) async {
    if (_currentRoom == null || _currentPlayer == null) return;
    
    try {
      await _supabaseService.submitAnswer(
        roomId: _currentRoom!.id,
        playerId: _currentPlayer!.id,
        answer: answer,
      );
    } catch (e) {
      _errorMessage = '提交答案失败: $e';
      notifyListeners();
    }
  }
  
  // 提交猜词（你画我猜）
  Future<void> submitGuess(String guess) async {
    if (_currentRoom == null || _currentPlayer == null) return;
    
    try {
      await _supabaseService.submitGuess(
        roomId: _currentRoom!.id,
        playerId: _currentPlayer!.id,
        guess: guess,
      );
    } catch (e) {
      _errorMessage = '提交猜词失败: $e';
      notifyListeners();
    }
  }
  
  // 发送作画动作
  Future<void> sendDrawingAction(DrawingAction action) async {
    if (_currentRoom == null) return;
    
    try {
      await _supabaseService.sendDrawingAction(
        roomId: _currentRoom!.id,
        action: action,
      );
    } catch (e) {
      _errorMessage = '发送作画动作失败: $e';
      notifyListeners();
    }
  }
}

// 游戏模式
enum GameMode {
  questionAnswer,
  drawAndGuess,
}

// 房间状态
enum RoomStatus {
  waiting,
  playing,
  ended,
}
