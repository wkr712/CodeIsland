## 新手村 - 游戏场景脚本
## 负责场景初始化、NPC配置和对话处理
class_name Village
extends Node2D

# ==================== 节点引用 ====================
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var village_chief: CharacterBody2D = $Entities/NPCs/VillageChief
@onready var hud: CanvasLayer = $HUD

# ==================== 变量 ====================
var _dialogue_ui: Control = null


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_scene()
	_setup_npcs()
	print("[Village] 新手村场景加载完成")


# ==================== 公共方法 ====================
## 获取玩家出生点
func get_spawn_point() -> Vector2:
	var spawn := $Entities/PlayerSpawn as Marker2D
	if spawn:
		return spawn.global_position
	return Vector2.ZERO


## 显示对话
func show_dialogue(speaker_name: String, text: String) -> void:
	if _dialogue_ui == null:
		_create_dialogue_ui()

	if _dialogue_ui:
		_dialogue_ui.show_dialogue(speaker_name, text)
		player.disable_movement()


## 隐藏对话
func hide_dialogue() -> void:
	if _dialogue_ui:
		_dialogue_ui.hide_dialogue()
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


func _setup_npcs() -> void:
	# 连接村长NPC信号
	if village_chief:
		village_chief.dialogue_started.connect(_on_npc_dialogue_started)
		village_chief.interacted.connect(_on_npc_interacted)


func _create_dialogue_ui() -> void:
	# 创建简单的对话UI
	_dialogue_ui = Control.new()
	_dialogue_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialogue_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.custom_minimum_size = Vector2(600, 150)
	panel.position = Vector2(-300, -180)
	_dialogue_ui.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 10
	vbox.offset_right = -20
	vbox.offset_bottom = -10
	panel.add_child(vbox)

	var name_label := Label.new()
	name_label.name = "SpeakerName"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.8))
	vbox.add_child(name_label)

	var content_label := Label.new()
	content_label.name = "Content"
	content_label.add_theme_font_size_override("font_size", 16)
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(content_label)

	var hint_label := Label.new()
	hint_label.name = "Hint"
	hint_label.text = "[点击继续]"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hint_label)

	_dialogue_ui.hide()
	add_child(_dialogue_ui)

	# 连接点击事件
	_dialogue_ui.gui_input.connect(_on_dialogue_input)


# ==================== 对话数据 ====================
const DIALOGUES := {
	"village_chief_intro": {
		"speaker": "村长",
		"lines": [
			"欢迎来到代码岛，年轻的旅行者！",
			"这里是新手村，你将在这里开始你的Python学习之旅。",
			"我是村长，我会引导你完成第一个任务。",
			"按下E键与我交互可以开始对话，使用WASD或方向键移动。",
			"准备好了吗？让我们开始吧！"
		]
	}
}

var _current_dialogue_lines: Array = []
var _current_dialogue_index: int = 0


# ==================== 信号处理 ====================
func _on_npc_interacted(npc: Node) -> void:
	if npc == village_chief:
		_start_dialogue("village_chief_intro")


func _on_npc_dialogue_started(_npc: CharacterBody2D) -> void:
	# 对话开始时的处理
	pass


func _start_dialogue(dialogue_id: String) -> void:
	if not DIALOGUES.has(dialogue_id):
		return

	var dialogue_data = DIALOGUES[dialogue_id]
	_current_dialogue_lines = dialogue_data["lines"]
	_current_dialogue_index = 0

	_show_current_dialogue_line(dialogue_data["speaker"])


func _show_current_dialogue_line(speaker: String) -> void:
	if _dialogue_ui == null:
		_create_dialogue_ui()

	if _current_dialogue_index >= _current_dialogue_lines.size():
		hide_dialogue()
		return

	var text = _current_dialogue_lines[_current_dialogue_index]

	# 获取UI元素
	var panel = _dialogue_ui.get_child(0)
	var vbox = panel.get_child(0)
	var name_label = vbox.get_node("SpeakerName") as Label
	var content_label = vbox.get_node("Content") as Label

	name_label.text = speaker
	content_label.text = text

	_dialogue_ui.show()
	_dialogue_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	player.disable_movement()


func _on_dialogue_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance_dialogue()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance_dialogue()


func _advance_dialogue() -> void:
	_current_dialogue_index += 1

	if _current_dialogue_index >= _current_dialogue_lines.size():
		hide_dialogue()
	else:
		var dialogue_data = DIALOGUES["village_chief_intro"]
		_show_current_dialogue_line(dialogue_data["speaker"])


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _dialogue_ui and _dialogue_ui.visible:
		_advance_dialogue()
		get_viewport().set_input_as_handled()
