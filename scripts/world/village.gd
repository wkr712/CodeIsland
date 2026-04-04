## 新手村 - 游戏场景脚本
## 负责场景初始化、NPC配置和对话处理
class_name Village
extends Node2D

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

# ==================== 变量 ====================
var _is_dialogue_active: bool = false


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
	_speaker_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_speaker_label.add_theme_constant_override("outline_size", 2)
	vbox.add_child(_speaker_label)

	# 对话内容
	_content_label = Label.new()
	_content_label.name = "Content"
	_content_label.add_theme_font_size_override("font_size", 18)
	_content_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_content_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_content_label.add_theme_constant_override("outline_size", 1)
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
			"准备好了吗？让我们开始第一个任务吧！"
		]
	}
}

var _current_dialogue_id: String = ""
var _current_line_index: int = 0


# ==================== 信号处理 ====================
func _on_player_interacted(target: Node) -> void:
	print("[Village] 玩家交互对象: ", target.name if target else "null")

	# 检查是否与村长交互
	if target == village_chief:
		_start_dialogue("village_chief_intro")
		return

	# 检查目标是否有interact方法
	if target.has_method("interact"):
		target.interact(player)


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
		hide_dialogue()
		_current_dialogue_id = ""
	else:
		_content_label.text = dialogue.lines[_current_line_index]
