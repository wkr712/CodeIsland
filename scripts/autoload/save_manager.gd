## 存档管理器
class_name SaveManager
extends Node

const MAX_SAVE_SLOTS := 3

func _ready() -> void:
	print("[SaveManager] 存档管理器初始化完成")

func has_save(slot: int) -> bool:
	return false

func get_save_info(slot: int) -> Dictionary:
	return {}
