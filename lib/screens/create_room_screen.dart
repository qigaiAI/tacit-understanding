import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacit_understanding/providers/game_provider.dart';
import 'package:tacit_understanding/screens/waiting_room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 生成随机昵称
    _nameController.text = '玩家${(1000 + DateTime.now().millisecond % 9000).toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建房间'),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 60 : 20,
          vertical: 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 昵称输入
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '昵称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // 游戏模式选择
            const Text('游戏模式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<GameMode>(
                    title: const Text('默契问答'),
                    value: GameMode.questionAnswer,
                    groupValue: gameProvider.gameMode,
                    onChanged: (value) {
                      if (value != null) {
                        gameProvider.gameMode = value;
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<GameMode>(
                    title: const Text('你画我猜'),
                    value: GameMode.drawAndGuess,
                    groupValue: gameProvider.gameMode,
                    onChanged: (value) {
                      if (value != null) {
                        gameProvider.gameMode = value;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 人数设置
            const Text('最大人数', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('${gameProvider.maxPlayers}人'),
                Expanded(
                  child: Slider(
                    value: gameProvider.maxPlayers.toDouble(),
                    min: 2,
                    max: 10,
                    divisions: 8,
                    onChanged: (value) {
                      gameProvider.maxPlayers = value.toInt();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 轮次设置（默契问答）
            if (gameProvider.gameMode == GameMode.questionAnswer) ...[
              const Text('轮次数', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${gameProvider.rounds}轮'),
                  Expanded(
                    child: Slider(
                      value: gameProvider.rounds.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (value) {
                        gameProvider.rounds = value.toInt();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 作画时间设置（你画我猜）
            if (gameProvider.gameMode == GameMode.drawAndGuess) ...[
              const Text('作画时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${gameProvider.drawingTime}秒'),
                  Expanded(
                    child: Slider(
                      value: gameProvider.drawingTime.toDouble(),
                      min: 30,
                      max: 120,
                      divisions: 9,
                      onChanged: (value) {
                        gameProvider.drawingTime = value.toInt();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 创建按钮
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入昵称')),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      final success = await gameProvider.createRoom(_nameController.text.trim());
                      setState(() => _isLoading = false);

                      if (success) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WaitingRoomScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(gameProvider.errorMessage ?? '创建房间失败')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('创建房间', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
