import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isMuted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMuted = prefs.getBool('isMuted') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMuted', _isMuted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 音效设置
            Card(
              child: ListTile(
                title: const Text('游戏音效'),
                trailing: Switch(
                  value: !_isMuted,
                  onChanged: (value) {
                    setState(() {
                      _isMuted = !value;
                      _saveSettings();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 关于
            Card(
              child: ListTile(
                title: const Text('关于'),
                subtitle: const Text('默契挑战 v1.0.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: '默契挑战',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 默契挑战',
                    children: [
                      const SizedBox(height: 10),
                      const Text('一个测试朋友间默契度的游戏应用'),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 清除缓存
            Card(
              child: ListTile(
                title: const Text('清除缓存'),
                onTap: () async {
                  setState(() => _isLoading = true);
                  // 模拟清除缓存
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('缓存已清除')),
                  );
                },
                trailing: _isLoading ? const CircularProgressIndicator() : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
