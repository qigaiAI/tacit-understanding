import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:tacit_understanding/providers/game_provider.dart';
import 'package:tacit_understanding/models/game_session.dart';
import 'package:tacit_understanding/config.dart';

class DrawAndGuessScreen extends StatefulWidget {
  const DrawAndGuessScreen({super.key});

  @override
  _DrawAndGuessScreenState createState() => _DrawAndGuessScreenState();
}

class _DrawAndGuessScreenState extends State<DrawAndGuessScreen> {
  late GameProvider _gameProvider;
  bool _isDrawing = false;
  List<Offset> _currentPath = [];
  Color _currentColor = Colors.black;
  double _currentWidth = 5.0;
  String _currentGuess = '';
  bool _hasGuessed = false;
  int _timeLeft = Config.defaultDrawingTime;
  late String _currentWord;
  late bool _isDrawer;

  @override
  void initState() {
    super.initState();
    _gameProvider = Provider.of<GameProvider>(context, listen: false);
    _initGame();
  }

  void _initGame() {
    // 初始化游戏数据
    final session = _gameProvider.currentSession;
    if (session != null) {
      _currentWord = session.currentWord ?? '';
      _isDrawer = session.drawerId == _gameProvider.currentPlayer?.id;
      _startCountdown();
    }
  }

  void _startCountdown() {
    // 启动倒计时
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
        _startCountdown();
      } else if (mounted) {
        _endRound();
      }
    });
  }

  void _endRound() {
    // 结束当前回合
    // 这里可以添加结束回合的逻辑
  }

  void _startDrawing(DragStartDetails details) {
    if (!_isDrawer) return;
    setState(() {
      _isDrawing = true;
      _currentPath = [details.localPosition];
    });
  }

  void _draw(DragUpdateDetails details) {
    if (!_isDrawing || !_isDrawer) return;
    setState(() {
      _currentPath.add(details.localPosition);
    });
  }

  void _endDrawing(DragEndDetails details) {
    if (!_isDrawer) return;
    setState(() {
      _isDrawing = false;
      _sendDrawingAction();
      _currentPath = [];
    });
  }

  void _sendDrawingAction() {
    // 发送作画动作到服务器
    if (_currentPath.isNotEmpty) {
      // 转换为DrawingOffset
      final points = _currentPath.map((offset) => DrawingOffset(offset.dx, offset.dy)).toList();
      final action = DrawingAction(
        type: 'draw',
        points: points,
        timestamp: DateTime.now(),
      );
      _gameProvider.sendDrawingAction(action);
    }
  }

  void _clearCanvas() {
    if (!_isDrawer) return;
    final action = DrawingAction(
      type: 'clear',
      timestamp: DateTime.now(),
    );
    _gameProvider.sendDrawingAction(action);
  }

  void _submitGuess() {
    if (_isDrawer || _hasGuessed || _currentGuess.isEmpty) return;
    _gameProvider.submitGuess(_currentGuess);
    setState(() {
      _hasGuessed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('你画我猜'),
        actions: [
          Text('时间: $_timeLefts', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          // 游戏信息
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('当前回合: ${_gameProvider.currentSession?.currentRound ?? 1}/${_gameProvider.rounds}'),
                if (_isDrawer)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '你要画: $_currentWord',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (!_isDrawer)
                  const Text('猜词中...'),
              ],
            ),
          ),

          // 画板
          Expanded(
            child: GestureDetector(
              onPanStart: _startDrawing,
              onPanUpdate: _draw,
              onPanEnd: _endDrawing,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: Colors.white,
                ),
                child: CustomPaint(
                  painter: DrawingPainter(
                    drawingActions: _gameProvider.currentSession?.drawingActions ?? [],
                    currentPath: _isDrawing ? _currentPath : [],
                    currentColor: _currentColor,
                    currentWidth: _currentWidth,
                  ),
                ),
              ),
            ),
          ),

          // 工具栏
          if (_isDrawer)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 颜色选择
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _colorButton(Colors.black),
                      _colorButton(Colors.red),
                      _colorButton(Colors.blue),
                      _colorButton(Colors.green),
                      _colorButton(Colors.yellow),
                      _colorButton(Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 画笔大小
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _widthButton(2.0),
                      _widthButton(5.0),
                      _widthButton(10.0),
                      _widthButton(20.0),
                      ElevatedButton(
                        onPressed: _clearCanvas,
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 猜词输入
          if (!_isDrawer && !_hasGuessed)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: '输入你的猜测',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _currentGuess = value;
                        });
                      },
                      onSubmitted: (value) {
                        _submitGuess();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _submitGuess,
                    child: const Text('提交'),
                  ),
                ],
              ),
            ),

          // 猜词结果
          if (!_isDrawer && _hasGuessed)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text('已提交猜测，等待结果...'),
            ),

          // 玩家列表
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('玩家列表:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _gameProvider.players.map((player) {
                    return Chip(
                      label: Text(
                        '${player.name} (${player.score})',
                        style: TextStyle(
                          color: player.id == _gameProvider.currentPlayer?.id ? Colors.blue : null,
                          fontWeight: player.id == _gameProvider.currentSession?.drawerId ? FontWeight.bold : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: _currentColor == color ? Border.all(color: Colors.black, width: 2) : null,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _widthButton(double width) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentWidth = width;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: _currentWidth == width ? Border.all(color: Colors.black, width: 2) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Container(
            width: width,
            height: width,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  String get _timeLefts {
    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingAction> drawingActions;
  final List<Offset> currentPath;
  final Color currentColor;
  final double currentWidth;

  DrawingPainter({
    required this.drawingActions,
    required this.currentPath,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制所有历史动作
    for (final action in drawingActions) {
      if (action.type == 'draw' && action.points != null) {
        // 转换DrawingOffset为Offset
        final path = action.points!.map((p) => Offset(p.dx, p.dy)).toList();
        final paint = Paint()
          ..color = Colors.black
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        if (path.length > 1) {
          canvas.drawPoints(PointMode.polygon, path, paint);
        }
      } else if (action.type == 'clear') {
        // 清空画布
        canvas.drawColor(Colors.white, BlendMode.clear);
      }
    }

    // 绘制当前路径
    if (currentPath.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPoints(PointMode.polygon, currentPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.drawingActions != drawingActions ||
        oldDelegate.currentPath != currentPath ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentWidth != currentWidth;
  }
}
