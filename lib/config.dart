// 配置文件 - 请根据实际部署的Supabase服务器修改
class Config {
  // Supabase配置
  static const String supabaseUrl = 'http://122.51.83.184:8000';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzQzMjM1MjAwLCJleHAiOjE4OTk5OTk5OTl9.g5xPKcjs_Yt3-XBYdNTVZ0P4A91Uura4dMb3xOr64LQ';
  
  // 游戏配置
  static const int maxPlayers = 10;
  static const int minPlayers = 2;
  static const int defaultRounds = 3;
  static const int defaultDrawingTime = 80; // 秒
  static const int defaultAnswerTime = 30; // 秒
  
  // 得分规则
  static const Map<int, int> guessingScores = {
    1: 3,
    2: 2,
    3: 1,
  };
  static const int baseDrawerScore = 2;
  static const int maxDrawerScore = 4;
  
  // 题库配置
  static const int minPresetQuestions = 100;
  static const int minPresetWords = 100;
  
  // 网络配置
  static const int reconnectionAttempts = 3;
  static const int reconnectionDelay = 2000; // 毫秒
  static const int gameProgressTimeout = 600; // 10分钟，秒
  
  // 画板配置
  static const int maxUndoSteps = 5;
  static const int drawingSyncDelay = 300; // 毫秒
  
  // 房间配置
  static const int roomCodeLength = 6;
  static const int roomCodeMaxAttempts = 5;
}
