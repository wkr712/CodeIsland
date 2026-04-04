## 新手村 - 游戏场景脚本
## 负责场景初始化、NPC配置和对话处理
class_name Village
extends Node2D

# ==================== 信号 ====================
signal dialogue_completed(dialogue_id: String)
signal quest_accepted(quest_id: String)

# ==================== 预加载 ====================
const CodeEditorPanelScene = preload("res://scenes/ui/code_editor_panel.tscn")

# ==================== 节点引用 ====================
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var village_chief: CharacterBody2D = $Entities/NPCs/VillageChief
@onready var hud: CanvasLayer = $HUD

# ==================== UI节点 ====================
var _dialogue_panel: PanelContainer = null
var _speaker_label: Label = null
var _content_label: Label = null
var _hint_label: Label = null
var _code_editor_panel: Control = null

# ==================== 状态变量 ====================
var _is_dialogue_active: bool = false
var _dialogue_completed := {}  # 跟踪已完成的对话
var _current_dialogue_id: String = ""
var _current_line_index: int = 0

# ==================== 任务状态 ====================
var _current_quest_id: String = ""
var _current_lesson_id: String = ""
var _quest_stage: String = ""  # "", "offered", "accepted", "coding", "completed"


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_scene()
	_setup_player_signals()
	_create_dialogue_ui()
	print("[Village] 新手村场景加载完成")


# ==================== 公共方法 ====================
## 显示对话
func show_dialogue(speaker: String, text: String) -> void:
	if _dialogue_panel == null:
		_create_dialogue_ui()

	_speaker_label.text = speaker
	_content_label.text = text
	_dialogue_panel.visible = true
	_is_dialogue_active = true

	# 禁用玩家移动
	if player.has_method("disable_movement"):
		player.disable_movement()


## 隐藏对话
func hide_dialogue() -> void:
	if _dialogue_panel:
		_dialogue_panel.visible = false
	_is_dialogue_active = false

	# 启用玩家移动
	if player.has_method("enable_movement"):
		player.enable_movement()


# ==================== 私有方法 ====================
func _setup_scene() -> void:
	# 设置相机跟随
	if player and camera:
		camera.global_position = player.global_position

	# 播放背景音乐
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_bgm("village_peaceful")


func _setup_player_signals() -> void:
	# 连接玩家的交互信号
	if player:
		if player.has_signal("interacted"):
			player.interacted.connect(_on_player_interacted)


func _create_dialogue_ui() -> void:
	# 创建对话面板
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.name = "DialoguePanel"

	# 设置面板样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.3, 0.6, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	_dialogue_panel.add_theme_stylebox_override("panel", style)

	# 设置位置和大小
	_dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dialogue_panel.custom_minimum_size = Vector2(700, 160)
	_dialogue_panel.position = Vector2(-350, -200)

	# 创建垂直容器
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_dialogue_panel.add_child(vbox)

	# 角色名称
	_speaker_label = Label.new()
	_speaker_label.name = "SpeakerName"
	_speaker_label.add_theme_font_size_override("font_size", 22)
	_speaker_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(_speaker_label)

	# 对话内容
	_content_label = Label.new()
	_content_label.name = "Content"
	_content_label.add_theme_font_size_override("font_size", 18)
	_content_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content_label.custom_minimum_size.y = 60
	vbox.add_child(_content_label)

	# 继续提示
	_hint_label = Label.new()
	_hint_label.name = "Hint"
	_hint_label.text = "▼ 按 E 或点击继续"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(_hint_label)

	_dialogue_panel.visible = false
	add_child(_dialogue_panel)


# ==================== 对话数据 ====================
const DIALOGUES := {
	"village_chief_intro": {
		"speaker": "👴 村长",
		"lines": [
			"欢迎来到代码岛，年轻的旅行者！",
			"这里是新手村，你将在这里开始你的 Python 学习之旅。",
			"我是村长，会引导你完成各种编程任务。",
			"看起来你是个有潜力的程序员。我有个任务要交给你！"
		],
		"next_action": "offer_quest"  # 对话完成后的动作
	},
	"village_chief_quest": {
		"speaker": "👴 村长",
		"lines": [
			"准备好了吗？让我们开始学习第一个概念：变量！",
			"点击下面的[开始任务]按钮打开代码编辑器。"
		],
		"next_action": "open_code_editor"
	},
	"village_chief_wait": {
		"speaker": "👴 村长",
		"lines": [
			"别忘了完成你的任务！去找代码站练习吧。",
			"代码站就在那边蓝色的位置。"
		],
		"next_action": "none"
	},
	"village_chief_complete": {
		"speaker": "👴 村长",
		"lines": [
			"太棒了！你完成了第一个任务！",
			"你现在已经掌握了变量的基本概念。",
			"继续加油，还有更多精彩的内容等着你！"
		],
		"next_action": "none"
	}
}


# ==================== 信号处理 ====================
func _on_player_interacted(target: Node) -> void:
	print("[Village] 玩家交互对象: ", target.name if target else "null")

	# 检查是否与村长交互
	if target == village_chief:
		_handle_chief_interaction()
		return

	# 检查目标是否有interact方法
	if target.has_method("interact"):
		target.interact(player)


func _handle_chief_interaction() -> void:
	# 根据任务状态决定对话内容
	if _quest_stage == "completed":
		# 任务已完成
		_start_dialogue("village_chief_complete")
	elif _quest_stage == "accepted" or _quest_stage == "coding":
		# 任务进行中
		_start_dialogue("village_chief_wait")
	elif _dialogue_completed.get("village_chief_intro", false):
		# 介绍对话已完成，显示任务对话
		_start_dialogue("village_chief_quest")
	else:
		# 首次对话
		_start_dialogue("village_chief_intro")


func _input(event: InputEvent) -> void:
	# 处理对话中的输入
	if _is_dialogue_active:
		if event.is_action_pressed("interact"):
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed:
			_advance_dialogue()
			get_viewport().set_input_as_handled()


func _start_dialogue(dialogue_id: String) -> void:
	if not DIALOGUES.has(dialogue_id):
		print("[Village] 对话不存在: ", dialogue_id)
		return

	_current_dialogue_id = dialogue_id
	_current_line_index = 0

	var dialogue = DIALOGUES[dialogue_id]
	show_dialogue(dialogue.speaker, dialogue.lines[0])


func _advance_dialogue() -> void:
	var dialogue = DIALOGUES.get(_current_dialogue_id)
	if dialogue == null:
		hide_dialogue()
		return

	_current_line_index += 1

	if _current_line_index >= dialogue.lines.size():
		# 对话结束
		_dialogue_completed[_current_dialogue_id] = true
		hide_dialogue()

		# 处理对话后的动作
		_handle_dialogue_complete(_current_dialogue_id, dialogue.get("next_action", "none"))
	else:
		_content_label.text = dialogue.lines[_current_line_index]


func _handle_dialogue_complete(dialogue_id: String, next_action: String) -> void:
	match next_action:
		"offer_quest":
			# 提供任务
			_show_quest_offer()
		"open_code_editor":
			# 打开代码编辑器
			_open_code_editor()
		"none":
			# 无动作
			pass


func _show_quest_offer() -> void:
	# 显示任务提示
	_show_message("📋 新任务：村长的委托 - 学习变量概念", 3.0)
	_quest_stage = "offered"

	# 更新HUD显示任务
	_update_hud_quest("村长的委托", "前往代码站学习变量")


func _show_message(text: String, duration: float = 3.0) -> void:
	# 通过HUD显示消息
	if hud and hud.has_method("show_message"):
		hud.show_message(text, duration)


func _update_hud_quest(title: String, description: String) -> void:
	if hud and hud.has_method("set_current_quest"):
		hud.set_current_quest(title, description)


func _open_code_editor() -> void:
	_quest_stage = "coding"
	_current_lesson_id = "lesson_1_1"
	print("[Village] 打开代码编辑器")

	# 创建或显示代码编辑器
	if _code_editor_panel == null:
		_code_editor_panel = CodeEditorPanelScene.instantiate()
		_code_editor_panel.lesson_completed.connect(_on_lesson_completed)
		_code_editor_panel.editor_closed.connect(_on_code_editor_closed)
		add_child(_code_editor_panel)

	# 加载课程数据
	var lesson_data = _load_lesson(_current_lesson_id)
	_code_editor_panel.load_lesson(lesson_data)

	# 禁用玩家移动
	if player.has_method("disable_movement"):
		player.disable_movement()


func _load_lesson(lesson_id: String) -> Dictionary:
	# 加载课程JSON数据
	var file_path = "res://data/lessons/chapter_1.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("[Village] 无法加载课程文件")
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("[Village] JSON解析错误")
		return {}

	var data = json.data
	for lesson in data.get("lessons", []):
		if lesson.get("id") == lesson_id:
			return lesson

	return {}


func _on_lesson_completed(lesson_id: String) -> void:
	print("[Village] 课程完成: ", lesson_id)
	complete_quest()


func _on_code_editor_closed() -> void:
	# 启用玩家移动
	if player.has_method("enable_movement"):
		player.enable_movement()


## 接受任务
func accept_quest() -> void:
	_quest_stage = "accepted"
	_current_quest_id = "quest_1_1"
	emit_signal("quest_accepted", _current_quest_id)


## 完成任务
func complete_quest() -> void:
	_quest_stage = "completed"
	_show_message("🎉 任务完成！获得 100 经验值", 3.0)

	# 更新玩家数据
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.player_data:
		game_manager.player_data["xp"] = game_manager.player_data.get("xp", 0) + 100

	# 更新HUD
	if hud and hud.has_method("update_player_info"):
		hud.update_player_info()
	if hud and hud.has_method("clear_quest_display"):
		hud.clear_quest_display()
