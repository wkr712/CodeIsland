## 代码编辑器面板
## 用于编写和运行Python代码的学习界面
class_name CodeEditorPanel
extends PanelContainer

# ==================== 信号 ====================
signal code_submitted(code: String)
signal lesson_completed(lesson_id: String)
signal editor_closed()

# ==================== 节点引用 ====================
@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var close_button: Button = $VBox/Header/CloseButton
@onready var lesson_title: Label = $VBox/LessonInfo/VBox/LessonTitle
@onready var lesson_desc: Label = $VBox/LessonInfo/VBox/LessonDesc
@onready var code_input: TextEdit = $VBox/CodeSection/CodeInput
@onready var output_text: Label = $VBox/OutputSection/OutputPanel/OutputText
@onready var hint_button: Button = $VBox/ButtonRow/HintButton
@onready var reset_button: Button = $VBox/ButtonRow/ResetButton
@onready var run_button: Button = $VBox/ButtonRow/RunButton
@onready var submit_button: Button = $VBox/ButtonRow/SubmitButton

# ==================== 变量 ====================
var _current_lesson: Dictionary = {}
var _hints: Array = []
var _current_hint_index: int = 0


# ==================== 生命周期 ====================
func _ready() -> void:
	_connect_signals()
	visible = false


func _connect_signals() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if hint_button:
		hint_button.pressed.connect(_on_hint_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if run_button:
		run_button.pressed.connect(_on_run_pressed)
	if submit_button:
		submit_button.pressed.connect(_on_submit_pressed)


# ==================== 公共方法 ====================
## 加载课程数据
func load_lesson(lesson_data: Dictionary) -> void:
	_current_lesson = lesson_data
	_current_hint_index = 0

	# 更新UI
	if lesson_title:
		lesson_title.text = "课程：%s" % lesson_data.get("title", "未知")

	if lesson_desc:
		lesson_desc.text = lesson_data.get("description", "")

	if code_input:
		code_input.text = lesson_data.get("starter_code", "")

	if output_text:
		output_text.text = "等待运行..."

	_hints = lesson_data.get("hints", [])
	visible = true


## 显示输出
func show_output(text: String, is_error: bool = false) -> void:
	if output_text:
		output_text.text = text
		if is_error:
			output_text.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		else:
			output_text.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))


## 关闭编辑器
func close() -> void:
	visible = false
	emit_signal("editor_closed")


# ==================== 私有方法 ====================
func _on_close_pressed() -> void:
	close()


func _on_hint_pressed() -> void:
	if _hints.is_empty():
		show_output("暂无提示", false)
		return

	var hint = _hints[_current_hint_index]
	show_output("💡 提示 %d/%d: %s" % [_current_hint_index + 1, _hints.size(), hint], false)

	_current_hint_index = (_current_hint_index + 1) % _hints.size()


func _on_reset_pressed() -> void:
	if code_input and _current_lesson:
		code_input.text = _current_lesson.get("starter_code", "")
		if output_text:
			output_text.text = "代码已重置"


func _on_run_pressed() -> void:
	if code_input == null:
		return

	var code = code_input.text
	if code.strip_edges().is_empty():
		show_output("请输入代码后再运行", true)
		return

	# 调用Python执行器
	var python_executor = get_node_or_null("/root/PythonExecutor")
	if python_executor:
		var result = python_executor.execute(code)
		if result.get("success", false):
			var output = result.get("output", "")
			if output.is_empty():
				output = "(代码执行成功，无输出)"
			show_output(output, false)
		else:
			show_output("错误: " + result.get("error", "未知错误"), true)
	else:
		# 模拟执行（开发模式）
		_simulate_execution(code)


func _on_submit_pressed() -> void:
	if code_input == null:
		return

	var code = code_input.text
	if code.strip_edges().is_empty():
		show_output("请输入代码后再提交", true)
		return

	# 验证代码
	if _validate_code(code):
		show_output("🎉 正确！课程完成！", false)
		emit_signal("lesson_completed", _current_lesson.get("id", ""))
		# 延迟关闭
		await get_tree().create_timer(2.0).timeout
		close()
	else:
		show_output("❌ 代码不正确，请再试一次", true)


func _validate_code(code: String) -> bool:
	var validation = _current_lesson.get("validation", {})

	if validation.is_empty():
		return true

	var validation_type = validation.get("type", "pattern")

	match validation_type:
		"pattern":
			return _validate_patterns(code, validation)
		"output":
			return _validate_output(code, validation)
		_:
			return true


func _validate_patterns(code: String, validation: Dictionary) -> bool:
	var required_patterns = validation.get("required_patterns", [])

	for pattern in required_patterns:
		if not pattern in code:
			return false

	return true


func _validate_output(code: String, validation: Dictionary) -> bool:
	var expected_output = validation.get("expected_output", "")

	# 调用执行器获取输出
	var python_executor = get_node_or_null("/root/PythonExecutor")
	if python_executor:
		var result = python_executor.execute(code)
		var actual_output = result.get("output", "").strip_edges()
		return actual_output == expected_output.strip_edges()

	# 模拟验证
	return true


func _simulate_execution(code: String) -> void:
	# 简单的模拟执行，用于开发测试
	var output = ""

	# 检测print语句
	var print_regex = RegEx.new()
	print_regex.compile('print\\s*\\(\\s*["\'](.+?)["\']\\s*\\)')
	var matches = print_regex.search_all(code)

	for match in matches:
		if match.get_string(1):
			output += match.get_string(1) + "\n"

	if output.is_empty():
		output = "(代码执行成功)"

	show_output(output.strip_edges(), false)
