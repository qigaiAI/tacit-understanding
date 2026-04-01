<<<<<<< HEAD
# 默契挑战 App

一个测试朋友间默契度的游戏应用，支持 2-10 人在线进行默契问答、你画我猜等挑战。

## 功能特点

- **默契问答**：轮流担任出题者，其他玩家回答关于出题者的问题
- **你画我猜**：接力版你画我猜，测试玩家的绘画能力和猜词能力
- **在线房间**：通过房间号加入游戏，支持多人同时在线
- **实时同步**：使用 WebSocket 实现状态同步，低延迟
- **多平台兼容**：支持 Android 和 iOS，手机和平板自适应布局

## 技术栈

- **客户端**：Flutter + Dart
- **状态管理**：Provider
- **后端**：Supabase（自托管）
- **本地存储**：shared_preferences

## 环境配置

### 1. 安装 Flutter

请确保你的开发环境已经安装了 Flutter SDK（最新稳定版）。

### 2. 配置 Supabase

#### 2.1 部署 Supabase（自托管）

在你的服务器上执行以下命令：

```bash
# 安装 Docker 和 Docker Compose（如果尚未安装）
# 克隆 Supabase 自托管仓库
git clone https://github.com/supabase/supabase
cd supabase/docker

# 复制环境变量模板
cp .env.example .env

# 编辑 .env，设置以下关键项：
# POSTGRES_PASSWORD=你的强密码
# JWT_SECRET=你的JWT密钥（生成一个随机字符串）
# ANON_KEY=公开密钥（可自动生成，但建议填写固定值）
# SERVICE_ROLE_KEY=服务角色密钥

# 启动服务
docker-compose up -d
```

#### 2.2 导入数据库表结构

在 Supabase 控制台的 SQL 编辑器中执行 `supabase_schema.sql` 文件中的 SQL 语句，创建所需的数据库表。

#### 2.3 配置客户端

编辑 `lib/config.dart` 文件，填入你的 Supabase 服务器信息：

```dart
// 配置文件 - 请根据实际部署的Supabase服务器修改
class Config {
  // Supabase配置
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  // ... 其他配置
}
```

### 3. 安装依赖

在项目根目录执行：

```bash
flutter pub get
```

## 运行项目

### 开发模式

```bash
flutter run
```

### 构建 APK

```bash
flutter build apk
```

### 构建 iOS 包

```bash
flutter build ios
```

## 项目结构

```
tacit-understanding/
├── lib/
│   ├── config.dart          # 配置文件
│   ├── main.dart            # 主入口
│   ├── app.dart             # 应用组件
│   ├── models/              # 数据模型
│   │   ├── room.dart        # 房间模型
│   │   ├── player.dart      # 玩家模型
│   │   └── game_session.dart # 游戏会话模型
│   ├── providers/           # 状态管理
│   │   └── game_provider.dart # 游戏状态管理
│   ├── screens/             # 屏幕组件
│   │   ├── splash_screen.dart     # 启动页
│   │   ├── home_screen.dart       # 首页
│   │   ├── create_room_screen.dart # 创建房间
│   │   ├── join_room_screen.dart   # 加入房间
│   │   ├── waiting_room_screen.dart # 等待房间
│   │   ├── question_answer_screen.dart # 默契问答
│   │   ├── draw_and_guess_screen.dart # 你画我猜
│   │   ├── settings_screen.dart    # 设置
│   │   └── history_screen.dart     # 历史记录
│   └── utils/               # 工具类
│       └── supabase_service.dart # Supabase服务
├── supabase_schema.sql      # 数据库表结构
├── pubspec.yaml             # 依赖配置
└── README.md                # 项目说明
```

## 游戏玩法

### 默契问答
1. 系统随机选择一名玩家作为出题者
2. 出题者可以选择预设题库或自定义问题
3. 其他玩家限时 30 秒作答
4. 答题结束后，出题者揭晓答案
5. 答案与真实答案一致的玩家得分
6. 轮流担任出题者，默认进行 3 轮

### 你画我猜
1. 系统随机选择一名玩家作为作画者
2. 作画者从题库中选择一个词进行绘画
3. 其他玩家实时观看画板并输入猜测
4. 按猜对顺序计分：第1个+3分，第2个+2分，第3个及以后+1分
5. 作画者得分：基础分2分 + 猜对人数（最多4分）
6. 轮流担任作画者

## 注意事项

- 确保你的 Supabase 服务器已经正确部署并可访问
- 网络不稳定时，应用会自动尝试重连
- 游戏数据会在本地存储最近 10 场游戏记录

## 后续迭代方向

- 增加动作同步模式
- 支持语音聊天
- 增加更多游戏模式（如“谁是卧底”“你比我猜”）
- 支持离线模式
=======
# tacit_understanding

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> 83a326a50cfe7d7fdbbaa6f69c237615669d85fe
