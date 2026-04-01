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
@onready var message_label: Label = $CenterContainer/MessageLabel
@onready var interaction_hint: Label = $BottomBar/InteractionHint
@onready var debug_label: Label = $DebugLabel

# ==================== 变量 ====================
var _current_quest_id: String = ""
var _message_timer: Timer


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_hud()
	_connect_signals()
	_hide_message()


func _process(_delta: float) -> void:
	if show_debug_info:
		_update_debug_info()


# ==================== 公共方法 ====================
## 更新玩家信息显示
func update_player_info() -> void:
	var player_data := GameManager.player_data

	if player_name_label:
		player_name_label.text = player_data.player_name

	if level_label:
		level_label.text = "Lv.%d" % player_data.get_level()

	if xp_bar:
		xp_bar.value = player_data.get_level_progress() * 100

	if chapter_label:
		chapter_label.text = "第%d章" % player_data.current_chapter


## 显示消息
func show_message(text: String, duration: float = 3.0) -> void:
	if message_label:
		message_label.text = text
		message_label.visible = true

		if _message_timer:
			_message_timer.stop()

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
	# 创建消息定时器
	_message_timer = Timer.new()
	_message_timer.one_shot = true
	add_child(_message_timer)

	# 初始化显示
	update_player_info()

	if quest_panel:
		quest_panel.visible = false

	if debug_label:
		debug_label.visible = show_debug_info


func _connect_signals() -> void:
	# 连接游戏管理器信号
	if GameManager:
		GameManager.chapter_unlocked.connect(_on_chapter_unlocked)
		GameManager.lesson_completed.connect(_on_lesson_completed)

	# 连接任务系统信号
	var quest_system := QuestSystem.new()
	if quest_system:
		quest_system.quest_accepted.connect(_on_quest_accepted)
		quest_system.quest_updated.connect(_on_quest_updated)
		quest_system.quest_completed.connect(_on_quest_completed)


func _update_quest_display() -> void:
	if _current_quest_id.is_empty():
		if quest_panel:
			quest_panel.visible = false
		return

	var quest := QuestSystem.get_quest(_current_quest_id)
	if quest == null:
		return

	if quest_panel:
		quest_panel.visible = true

	if quest_title:
		quest_title.text = quest.title

	# 更新目标列表
	if quest_objectives:
		for child in quest_objectives.get_children():
			child.queue_free()

		for i in quest.objectives.size():
			var objective = quest.objectives[i]
			var objective_label := Label.new()

			var checkmark := "☐" if not objective.is_completed else "☑"
			var progress := ""

			if objective.required_progress > 1:
				progress = " (%d/%d)" % [objective.current_progress, objective.required_progress]

			objective_label.text = "%s %s%s" % [checkmark, objective.description, progress]

			if objective.is_completed:
				objective_label.add_theme_color_override("font_color", Color.GREEN)

			quest_objectives.add_child(objective_label)


func _hide_message() -> void:
	if message_label:
		message_label.visible = false


func _update_debug_info() -> void:
	if debug_label:
		var fps := Engine.get_frames_per_second()
		debug_label.text = "FPS: %d" % fps


# ==================== 信号处理 ====================
func _on_chapter_unlocked(chapter: int) -> void:
	show_message("解锁新章节: 第%d章" % chapter, 4.0)
	update_player_info()


func _on_lesson_completed(lesson_id: String) -> void:
	show_message("完成课程: %s" % lesson_id, 2.0)
	update_player_info()


func _on_quest_accepted(quest_id: String) -> void:
	set_current_quest(quest_id)
	show_message("接受新任务", 2.0)


func _on_quest_updated(quest_id: String, _progress: int) -> void:
	if quest_id == _current_quest_id:
		_update_quest_display()


func _on_quest_completed(quest_id: String) -> void:
	if quest_id == _current_quest_id:
		var quest := QuestSystem.get_quest(quest_id)
		if quest:
			show_message("任务完成: %s" % quest.title, 3.0)
		clear_quest_display()
