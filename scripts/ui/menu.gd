## 主菜单 - UI脚本
## 游戏的主入口界面
class_name MainMenu
extends Control

# ==================== 节点引用 ====================
@onready var new_game_button: Button = $VBoxContainer/MenuButtons/NewGameButton
@onready var continue_button: Button = $VBoxContainer/MenuButtons/ContinueButton
@onready var settings_button: Button = $VBoxContainer/MenuButtons/SettingsButton
@onready var quit_button: Button = $VBoxContainer/MenuButtons/QuitButton

# ==================== 变量 ====================
var _has_saves: bool = false


# ==================== 生命周期 ====================
func _ready() -> void:
	print("[MainMenu] 主菜单加载完成")
	_connect_signals()
	_check_saves()


# ==================== 私有方法 ====================
func _connect_signals() -> void:
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _check_saves() -> void:
	# 简化：暂时没有存档
	_has_saves = false
	if continue_button:
		continue_button.disabled = true


# ==================== 信号处理 ====================
func _on_new_game_pressed() -> void:
	print("[MainMenu] 点击新游戏")
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/world/village.tscn")


func _on_continue_pressed() -> void:
	print("[MainMenu] 点击继续游戏")


func _on_settings_pressed() -> void:
	print("[MainMenu] 点击设置")
	print("设置功能开发中...")


func _on_quit_pressed() -> void:
	print("[MainMenu] 点击退出")
	get_tree().quit()
