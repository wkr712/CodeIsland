## 对话系统 - 核心系统
## 负责对话的加载、显示和交互
class_name DialogueSystem
extends Node

# ==================== 信号 ====================
signal dialogue_started(dialogue_id: String)
signal dialogue_line_displayed(speaker: String, text: String)
signal dialogue_choice_presented(choices: Array)
signal dialogue_choice_selected(choice_index: int)
signal dialogue_ended(dialogue_id: String)
signal quest_triggered(quest_id: String)

# ==================== 常量 ====================
const DIALOGUE_PATH := "res://data/dialogues/"

# ==================== 对话数据类 ====================
class DialogueLine:
	var speaker: String = ""
	var speaker_name: String = ""
	var portrait: String = ""
	var text: String = ""
	var choices: Array[Dictionary] = []
	var action: String = ""


class DialogueData:
	var dialogue_id: String = ""
	var npc_id: String = ""
	var trigger_condition: String = ""
	var lines: Array[DialogueLine] = []
	var current_line_index: int = 0


# ==================== 变量 ====================
var _current_dialogue: DialogueData = null
var _is_dialogue_active: bool = false
var _dialogue_cache: Dictionary = {}

# UI引用（由场景设置）
var _dialogue_ui: Control = null
var _speaker_label: Label = null
var _text_label: RichTextLabel = null
var _portrait_texture: TextureRect = null
var _choices_container: VBoxContainer = null


# ==================== 生命周期 ====================
func _ready() -> void:
	print("[DialogueSystem] 初始化对话系统...")
	_preload_dialogues()


func _input(event: InputEvent) -> void:
	if not _is_dialogue_active:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()


# ==================== 公共方法 ====================
## 开始对话
func start_dialogue(dialogue_id: String) -> bool:
	if _is_dialogue_active:
		push_warning("[DialogueSystem] 对话已在进行中")
		return false

	if not _dialogue_cache.has(dialogue_id):
		# 尝试加载对话
		if not _load_dialogue(dialogue_id):
			push_error("[DialogueSystem] 无法加载对话: %s" % dialogue_id)
			return false

	_current_dialogue = _dialogue_cache[dialogue_id]
	_current_dialogue.current_line_index = 0
	_is_dialogue_active = true

	emit_signal("dialogue_started", dialogue_id)

	# 显示第一行对话
	_display_current_line()

	return true


## 推进对话
func advance_dialogue() -> void:
	_advance_dialogue()


## 选择选项
func select_choice(choice_index: int) -> void:
	if _current_dialogue == null:
		return

	var current_line := _current_dialogue.lines[_current_dialogue.current_line_index]
	if choice_index < 0 or choice_index >= current_line.choices.size():
		return

	emit_signal("dialogue_choice_selected", choice_index)

	var choice: Dictionary = current_line.choices[choice_index]

	# 执行选项动作
	if choice.has("action"):
		_execute_action(choice.action)

	# 跳转到下一个对话
	if choice.has("next_dialogue"):
		end_dialogue()
		start_dialogue(choice.next_dialogue)
	else:
		_advance_dialogue()


## 结束对话
func end_dialogue() -> void:
	if _current_dialogue == null:
		return

	var dialogue_id := _current_dialogue.dialogue_id
	_current_dialogue = null
	_is_dialogue_active = false

	# 隐藏UI
	_hide_dialogue_ui()

	emit_signal("dialogue_ended", dialogue_id)


## 检查对话是否活动
func is_dialogue_active() -> bool:
	return _is_dialogue_active


## 设置UI引用
func set_ui_references(ui: Control, speaker: Label, text: RichTextLabel, portrait: TextureRect, choices: VBoxContainer) -> void:
	_dialogue_ui = ui
	_speaker_label = speaker
	_text_label = text
	_portrait_texture = portrait
	_choices_container = choices


# ==================== 私有方法 ====================
func _preload_dialogues() -> void:
	var dir := DirAccess.open(DIALOGUE_PATH)
	if dir == null:
		push_warning("[DialogueSystem] 无法打开对话数据目录")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".json"):
			var dialogue_id := file_name.replace(".json", "")
			_load_dialogue(dialogue_id)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("[DialogueSystem] 预加载了 %d 个对话" % _dialogue_cache.size())


func _load_dialogue(dialogue_id: String) -> bool:
	var file_path := DIALOGUE_PATH + dialogue_id + ".json"

	if not ResourceLoader.exists(file_path):
		return false

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		push_error("[DialogueSystem] 对话文件解析失败: %s" % file_path)
		return false

	var data: Dictionary = json.data
	var dialogue := _parse_dialogue_data(data)
	dialogue.dialogue_id = dialogue_id

	_dialogue_cache[dialogue_id] = dialogue
	return true


func _parse_dialogue_data(data: Dictionary) -> DialogueData:
	var dialogue := DialogueData.new()
	dialogue.npc_id = data.get("npc_id", "")
	dialogue.trigger_condition = data.get("trigger_condition", "")

	var lines_data: Array = data.get("dialogues", [])
	for line_data in lines_data:
		var line := DialogueLine.new()
		line.speaker = line_data.get("speaker", "")
		line.speaker_name = line_data.get("speaker_name", "")
		line.portrait = line_data.get("portrait", "")
		line.text = line_data.get("text", "")
		line.action = line_data.get("action", "")

		var choices_data: Array = line_data.get("choices", [])
		for choice_data in choices_data:
			line.choices.append(choice_data)

		dialogue.lines.append(line)

	return dialogue


func _display_current_line() -> void:
	if _current_dialogue == null:
		return

	if _current_dialogue.current_line_index >= _current_dialogue.lines.size():
		end_dialogue()
		return

	var line: DialogueLine = _current_dialogue.lines[_current_dialogue.current_line_index]

	# 更新UI
	_update_dialogue_ui(line)

	emit_signal("dialogue_line_displayed", line.speaker_name, line.text)

	# 显示选项
	if not line.choices.is_empty():
		_display_choices(line.choices)
		emit_signal("dialogue_choice_presented", line.choices)


func _update_dialogue_ui(line: DialogueLine) -> void:
	if _dialogue_ui:
		_dialogue_ui.show()

	if _speaker_label:
		_speaker_label.text = line.speaker_name

	if _text_label:
		# 打字机效果可以在这里实现
		_text_label.text = line.text

	if _portrait_texture:
		# 加载肖像
		if not line.portrait.is_empty():
			var portrait_path := "res://assets/sprites/portraits/%s.png" % line.portrait
			if ResourceLoader.exists(portrait_path):
				_portrait_texture.texture = load(portrait_path)
		else:
			_portrait_texture.texture = null


func _display_choices(choices: Array) -> void:
	if _choices_container == null:
		return

	# 清除旧选项
	for child in _choices_container.get_children():
		child.queue_free()

	# 创建新选项按钮
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.text = choice.get("text", "???")
		button.pressed.connect(_on_choice_button_pressed.bind(i))
		_choices_container.add_child(button)


func _hide_dialogue_ui() -> void:
	if _dialogue_ui:
		_dialogue_ui.hide()

	if _choices_container:
		for child in _choices_container.get_children():
			child.queue_free()


func _advance_dialogue() -> void:
	if _current_dialogue == null:
		return

	var current_line := _current_dialogue.lines[_current_dialogue.current_line_index]

	# 如果有选项，不能直接推进
	if not current_line.choices.is_empty():
		return

	# 执行动作
	if not current_line.action.is_empty():
		_execute_action(current_line.action)

	# 前进到下一行
	_current_dialogue.current_line_index += 1

	if _current_dialogue.current_line_index >= _current_dialogue.lines.size():
		end_dialogue()
	else:
		_display_current_line()


func _execute_action(action: String) -> void:
	# 解析动作字符串
	# 格式: "action_type:param1:param2"
	var parts := action.split(":")

	if parts.is_empty():
		return

	var action_type: String = parts[0]

	match action_type:
		"accept_quest":
			if parts.size() > 1:
				var quest_id: String = parts[1]
				emit_signal("quest_triggered", quest_id)

		"give_item":
			if parts.size() > 2:
				var item_id: String = parts[1]
				var count: int = parts[2].to_int()
				GameManager.player_data.add_item(item_id, count)

		"unlock_area":
			if parts.size() > 1:
				var area_id: String = parts[1]
				# TODO: 解锁区域逻辑

		"start_battle":
			# TODO: 战斗逻辑
			pass

		"teleport":
			if parts.size() > 2:
				var scene_path: String = parts[1]
				var spawn_point: String = parts[2]
				GameManager.change_scene(scene_path)

		_:
			push_warning("[DialogueSystem] 未知动作类型: %s" % action_type)


# ==================== 信号处理 ====================
func _on_choice_button_pressed(choice_index: int) -> void:
	select_choice(choice_index)
