import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacit_understanding/providers/game_provider.dart';
import 'package:tacit_understanding/screens/waiting_room_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  _JoinRoomScreenState createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
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
        title: const Text('加入房间'),
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
            // 房间号输入
            TextField(
              controller: _roomCodeController,
              decoration: const InputDecoration(
                labelText: '房间号',
                border: OutlineInputBorder(),
                hintText: '请输入6位数字房间号',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 20),

            // 昵称输入
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '昵称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),

            // 加入按钮
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final roomCode = _roomCodeController.text.trim();
                      final playerName = _nameController.text.trim();

                      if (roomCode.isEmpty || roomCode.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入正确的6位房间号')),
                        );
                        return;
                      }

                      if (playerName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入昵称')),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      final success = await gameProvider.joinRoom(roomCode, playerName);
                      setState(() => _isLoading = false);

                      if (success) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WaitingRoomScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(gameProvider.errorMessage ?? '加入房间失败')),
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
                  : const Text('加入房间', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
