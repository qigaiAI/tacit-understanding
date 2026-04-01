import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacit_understanding/providers/game_provider.dart';
import 'package:tacit_understanding/screens/question_answer_screen.dart';
import 'package:tacit_understanding/screens/draw_and_guess_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  _WaitingRoomScreenState createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final room = gameProvider.currentRoom;
    final player = gameProvider.currentPlayer;
    final players = gameProvider.players;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (room == null || player == null) {
      return Scaffold(
        body: Center(child: const Text('房间信息加载中...')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('等待房间'),
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
            // 房间号
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('房间号', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(
                      room.code,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // 复制房间号到剪贴板
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('房间号已复制')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue,
                      ),
                      child: const Text('复制房间号'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 玩家列表
            const Text('玩家列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 4 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final p = players[index];
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: p.isHost ? Colors.blue : Colors.grey,
                            child: Text(
                              p.name[0],
                              style: const TextStyle(color: Colors.white, fontSize: 24),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(p.name),
                          if (p.isHost) const Text('房主', style: TextStyle(fontSize: 12, color: Colors.blue)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 开始游戏按钮（仅房主可见）
            if (player.isHost) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (players.length < 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('至少需要2名玩家才能开始游戏')),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        final success = await gameProvider.startGame();
                        setState(() => _isLoading = false);

                        if (success) {
                          // 根据游戏模式跳转到对应屏幕
                          if (room.gameMode == GameMode.questionAnswer) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QuestionAnswerScreen()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DrawAndGuessScreen()),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(gameProvider.errorMessage ?? '开始游戏失败')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('开始游戏', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              const SizedBox(height: 20),
              const Center(
                child: Text('等待房主开始游戏...', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
