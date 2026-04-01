-- 创建房间表
CREATE TABLE rooms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code VARCHAR(6) NOT NULL UNIQUE,
  game_mode VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'waiting',
  max_players INTEGER NOT NULL,
  rounds INTEGER NOT NULL,
  drawing_time INTEGER NOT NULL,
  host_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- 创建玩家表
CREATE TABLE players (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES rooms(id),
  name VARCHAR(50) NOT NULL,
  is_host BOOLEAN NOT NULL DEFAULT false,
  score INTEGER NOT NULL DEFAULT 0,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  left_at TIMESTAMP WITH TIME ZONE
);

-- 创建游戏会话表
CREATE TABLE game_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES rooms(id),
  current_round INTEGER NOT NULL DEFAULT 1,
  current_question TEXT,
  current_word TEXT,
  drawer_id UUID REFERENCES players(id),
  questioner_id UUID REFERENCES players(id),
  answers JSONB DEFAULT '{}',
  guesses JSONB DEFAULT '{}',
  drawing_actions JSONB DEFAULT '[]',
  started_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  ended_at TIMESTAMP WITH TIME ZONE
);

-- 创建索引
CREATE INDEX idx_rooms_code ON rooms(code);
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_players_room_id ON players(room_id);
CREATE INDEX idx_players_left_at ON players(left_at);
CREATE INDEX idx_game_sessions_room_id ON game_sessions(room_id);
