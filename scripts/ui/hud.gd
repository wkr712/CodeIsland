## 游戏HUD - UI脚本
## 显示玩家状态、经验值、当前任务等信息
class_name HUD
extends CanvasLayer

# ==================== 节点引用 ====================
@onready var player_name_label: Label = $MarginContainer/VBox/TopBar/PlayerInfo/HBox/InfoVBox/NameRow/PlayerName
@onready var level_label: Label = $MarginContainer/VBox/TopBar/PlayerInfo/HBox/InfoVBox/NameRow/LevelLabel
@onready var xp_bar: ProgressBar = $MarginContainer/VBox/TopBar/PlayerInfo/HBox/InfoVBox/XPBar
@onready var chapter_label: Label = $MarginContainer/VBox/TopBar/ChapterInfo/ChapterLabel
@onready var message_label: Label = $MarginContainer/CenterContainer/MessageLabel
@onready var interaction_hint: PanelContainer = $MarginContainer/VBox/BottomBar/InteractionHint
@onready var quest_panel: PanelContainer = $MarginContainer/VBox/QuestPanel
@onready var quest_desc: Label = $MarginContainer/VBox/QuestPanel/VBox/QuestDesc

# ==================== 变量 ====================
var _current_quest_id: String = ""
var _message_tween: Tween = null


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_hud()


# ==================== 公共方法 ====================
## 更新玩家信息显示
func update_player_info() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return

	var data = game_manager.player_data
	if data.is_empty():
		return

	if player_name_label:
		player_name_label.text = data.get("name", "旅行者")

	if level_label:
		level_label.text = "Lv.%d" % data.get("level", 1)

	if xp_bar:
		xp_bar.value = data.get("xp", 0)

	if chapter_label:
		chapter_label.text = "📍 第%d章" % data.get("chapter", 1)


## 显示消息
func show_message(text: String, duration: float = 3.0) -> void:
	if message_label:
		message_label.text = text
		message_label.visible = true
		message_label.modulate.a = 1.0

		if _message_tween:
			_message_tween.kill()

		_message_tween = create_tween()
		_message_tween.tween_interval(duration)
		_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
		_message_tween.tween_callback(func(): message_label.visible = false)


## 显示交互提示
func show_interaction_hint(text: String) -> void:
	if interaction_hint:
		var hint_label = interaction_hint.get_node("HintLabel")
		if hint_label:
			hint_label.text = text
		interaction_hint.visible = true


## 隐藏交互提示
func hide_interaction_hint() -> void:
	if interaction_hint:
		interaction_hint.visible = false


## 设置当前任务
func set_current_quest(quest_id: String, description: String = "") -> void:
	_current_quest_id = quest_id
	if quest_panel:
		quest_panel.visible = true
	if quest_desc:
		quest_desc.text = description if description else "进行中..."


## 清除任务显示
func clear_quest_display() -> void:
	_current_quest_id = ""
	if quest_panel:
		quest_panel.visible = false


# ==================== 私有方法 ====================
func _setup_hud() -> void:
	update_player_info()

	if quest_panel:
		quest_panel.visible = false

	if interaction_hint:
		interaction_hint.visible = false

	if message_label:
		message_label.visible = false
