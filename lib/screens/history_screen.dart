import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GameHistory> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final historyData = prefs.getStringList('gameHistory') ?? [];
    
    setState(() {
      _history = historyData.map((data) {
        final parts = data.split('|');
        return GameHistory(
          time: DateTime.parse(parts[0]),
          mode: parts[1],
          players: parts[2],
          score: int.parse(parts[3]),
        );
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gameHistory');
    setState(() => _history = []);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('历史记录已清除')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _history.isEmpty ? null : _clearHistory,
            tooltip: '清除历史',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('暂无历史记录'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final history = _history[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  history.mode,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '得分: ${history.score}',
                                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('参与者: ${history.players}'),
                            const SizedBox(height: 8),
                            Text(
                              history.time.toString(),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class GameHistory {
  final DateTime time;
  final String mode;
  final String players;
  final int score;

  GameHistory({
    required this.time,
    required this.mode,
    required this.players,
    required this.score,
  });
}
