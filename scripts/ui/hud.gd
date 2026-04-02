## 游戏HUD - UI脚本
## 显示玩家状态、经验值、当前任务等信息
class_name HUD
extends CanvasLayer

# ==================== 信号 ====================
signal hud_visibility_changed(is_visible: bool)

# ==================== 导出变量 ====================
## 是否显示调试信息
@export var show_debug_info: bool = false

# ==================== 节点引用 ====================
@onready var player_name_label: Label = $MarginContainer/VBox/TopBar/PlayerInfo/PlayerName
@onready var level_label: Label = $MarginContainer/VBox/TopBar/PlayerInfo/LevelLabel
@onready var xp_bar: ProgressBar = $MarginContainer/VBox/TopBar/PlayerInfo/XPBar
@onready var chapter_label: Label = $MarginContainer/VBox/TopBar/ChapterInfo/ChapterLabel
@onready var quest_panel: PanelContainer = $MarginContainer/VBox/QuestPanel
@onready var quest_title: Label = $MarginContainer/VBox/QuestPanel/VBox/QuestTitle
@onready var quest_objectives: VBoxContainer = $MarginContainer/VBox/QuestPanel/VBox/Objectives
@onready var message_label: Label = $MarginContainer/CenterContainer/MessageLabel
@onready var interaction_hint: Label = $MarginContainer/VBox/BottomBar/InteractionHint

# ==================== 变量 ====================
var _current_quest_id: String = ""
var _message_timer: Timer


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_hud()
	_hide_message()


# ==================== 公共方法 ====================
## 更新玩家信息显示
func update_player_info() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return

	var player_data = game_manager.player_data
	if player_data.is_empty():
		return

	if player_name_label:
		player_name_label.text = player_data.get("name", "旅行者")

	if level_label:
		level_label.text = "Lv.%d" % player_data.get("level", 1)

	if xp_bar:
		xp_bar.value = player_data.get("xp", 0)

	if chapter_label:
		chapter_label.text = "第%d章" % player_data.get("chapter", 1)


## 显示消息
func show_message(text: String, duration: float = 3.0) -> void:
	if message_label:
		message_label.text = text
		message_label.visible = true

		if _message_timer:
			_message_timer.stop()
			_message_timer.queue_free()

		_message_timer = Timer.new()
		_message_timer.wait_time = duration
		_message_timer.one_shot = true
		_message_timer.timeout.connect(_hide_message)
		add_child(_message_timer)
		_message_timer.start()


## 显示交互提示
func show_interaction_hint(text: String) -> void:
	if interaction_hint:
		interaction_hint.text = text
		interaction_hint.visible = true


## 隐藏交互提示
func hide_interaction_hint() -> void:
	if interaction_hint:
		interaction_hint.visible = false


## 设置当前任务
func set_current_quest(quest_id: String) -> void:
	_current_quest_id = quest_id
	_update_quest_display()


## 清除任务显示
func clear_quest_display() -> void:
	_current_quest_id = ""
	if quest_panel:
		quest_panel.visible = false


# ==================== 私有方法 ====================
func _setup_hud() -> void:
	# 初始化显示
	update_player_info()

	if quest_panel:
		quest_panel.visible = false


func _update_quest_display() -> void:
	if _current_quest_id.is_empty():
		if quest_panel:
			quest_panel.visible = false
		return

	if quest_panel:
		quest_panel.visible = true

	if quest_title:
		quest_title.text = "当前任务: %s" % _current_quest_id


func _hide_message() -> void:
	if message_label:
		message_label.visible = false
