## 音频管理器
class_name AudioManager
extends Node

var bgm_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready() -> void:
	print("[AudioManager] 音频管理器初始化完成")

func play_bgm(name: String) -> void:
	print("[AudioManager] 播放BGM: ", name)

func play_sfx(name: String) -> void:
	print("[AudioManager] 播放SFX: ", name)
