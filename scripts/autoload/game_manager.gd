## 游戏管理器 - 核心单例
extends Node

# ==================== 信号 ====================
signal game_started
signal game_paused
signal game_resumed

# ==================== 枚举 ====================
enum GameState {
	MENU,
	PLAYING,
	PAUSED
}

# ==================== 变量 ====================
var current_state: GameState = GameState.MENU
var player_data: Dictionary = {}


# ==================== 生命周期 ====================
func _ready() -> void:
	print("[GameManager] 游戏管理器初始化完成")
	_init_player_data()


func _init_player_data() -> void:
	player_data = {
		"name": "旅行者",
		"level": 1,
		"chapter": 1,
		"xp": 0
	}


# ==================== 公共方法 ====================
func start_new_game() -> void:
	print("[GameManager] 开始新游戏")
	current_state = GameState.PLAYING
	_init_player_data()
	emit_signal("game_started")
