import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacit_understanding/providers/game_provider.dart';
import 'package:tacit_understanding/screens/create_room_screen.dart';
import 'package:tacit_understanding/screens/join_room_screen.dart';
import 'package:tacit_understanding/screens/settings_screen.dart';
import 'package:tacit_understanding/screens/history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('默契挑战'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 60 : 20,
            vertical: 40,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 主按钮区域
              isTablet
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildButton(
                          context,
                          '创建房间',
                          Colors.blue,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateRoomScreen()),
                          ),
                        ),
                        const SizedBox(width: 30),
                        _buildButton(
                          context,
                          '加入房间',
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JoinRoomScreen()),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildButton(
                          context,
                          '创建房间',
                          Colors.blue,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateRoomScreen()),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildButton(
                          context,
                          '加入房间',
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JoinRoomScreen()),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 40),
              // 辅助功能按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                    tooltip: '设置',
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HistoryScreen()),
                    ),
                    tooltip: '历史记录',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 60 : 40,
          vertical: isTablet ? 20 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTablet ? 20 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
