import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacit_understanding/providers/game_provider.dart';
import 'package:tacit_understanding/config.dart';

class QuestionAnswerScreen extends StatefulWidget {
  const QuestionAnswerScreen({super.key});

  @override
  _QuestionAnswerScreenState createState() => _QuestionAnswerScreenState();
}

class _QuestionAnswerScreenState extends State<QuestionAnswerScreen> {
  final TextEditingController _answerController = TextEditingController();
  int _timeLeft = Config.defaultAnswerTime;
  bool _hasSubmitted = false;
  List<String> _presetQuestions = [
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

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timeLeft > 0) {
        setState(() => _timeLeft--);
        _startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final room = gameProvider.currentRoom;
    final player = gameProvider.currentPlayer;
    final session = gameProvider.currentSession;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (room == null || player == null || session == null) {
      return Scaffold(
        body: Center(child: const Text('游戏信息加载中...')),
      );
    }

    final isQuestioner = player.id == session.questionerId;
    final currentQuestion = session.currentQuestion ?? _presetQuestions[session.currentRound % _presetQuestions.length];

    return Scaffold(
      appBar: AppBar(
        title: Text('默契问答 - 第${session.currentRound}轮'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await gameProvider.leaveRoom();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 60 : 20,
          vertical: 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 倒计时
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: Text(
                '$_timeLeft秒',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),

            // 出题者信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('当前出题者:', style: TextStyle(fontSize: 16)),
                    Text(
                      isQuestioner ? '你' : gameProvider.players.firstWhere((p) => p.id == session.questionerId).name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 问题
            Card(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  currentQuestion,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 答题区域
            if (!isQuestioner) ...[
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: '请输入答案',
                  border: OutlineInputBorder(),
                ),
                enabled: !_hasSubmitted,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _hasSubmitted
                    ? null
                    : () {
                        if (_answerController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入答案')),
                          );
                          return;
                        }
                        gameProvider.submitAnswer(_answerController.text.trim());
                        setState(() => _hasSubmitted = true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('提交答案', style: TextStyle(fontSize: 18)),
              ),
            ] else ...[
              const Center(
                child: Text('等待其他玩家回答...', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ),
            ],

            // 答案展示（出题者可见）
            if (isQuestioner && session.answers.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text('玩家答案:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: session.answers.length,
                  itemBuilder: (context, index) {
                    final entry = session.answers.entries.elementAt(index);
                    final playerName = gameProvider.players.firstWhere((p) => p.id == entry.key).name;
                    return ListTile(
                      title: Text(playerName),
                      subtitle: Text(entry.value),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // 揭晓答案
                  // 这里需要实现揭晓答案的逻辑
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('揭晓答案', style: TextStyle(fontSize: 18)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
