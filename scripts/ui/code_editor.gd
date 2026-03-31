## 代码编辑器 - UI脚本
## 提供Python代码编写、高亮、运行和验证功能
class_name CodeEditor
extends Control

# ==================== 信号 ====================
signal code_submitted(code: String)
signal code_validated(is_valid: bool)
signal hint_requested()
signal close_requested()

# ==================== 导出变量 ====================
## 当前课程ID
@export var lesson_id: String = ""

## 初始代码
@export_multiline var starter_code: String = "# 在这里编写你的代码\n"

## 任务描述
@export_multiline var task_description: String = "完成任务"

# ==================== 节点引用 ====================
@onready var title_label: Label = $Panel/VBox/Header/TitleLabel
@onready var task_label: RichTextLabel = $Panel/VBox/TaskSection/TaskLabel
@onready var code_edit: TextEdit = $Panel/VBox/CodeSection/CodeEdit
@onready var output_label: RichTextLabel = $Panel/VBox/OutputSection/OutputLabel
@onready var run_button: Button = $Panel/VBox/ButtonBar/RunButton
@onready var submit_button: Button = $Panel/VBox/ButtonBar/SubmitButton
@onready var hint_button: Button = $Panel/VBox/ButtonBar/HintButton
@onready var clear_button: Button = $Panel/VBox/ButtonBar/ClearButton
@onready var close_button: Button = $Panel/VBox/Header/CloseButton
@onready var progress_bar: ProgressBar = $Panel/VBox/OutputSection/ProgressBar
@onready var status_label: Label = $Panel/VBox/OutputSection/StatusLabel

# ==================== 变量 ====================
var _is_running: bool = false
var _current_code: String = ""
var _hints: Array[String] = []
var _current_hint_index: int = 0
var _validation_rules: Dictionary = {}

# Python语法高亮关键词
const PYTHON_KEYWORDS := [
	"False", "None", "True", "and", "as", "assert", "async", "await",
	"break", "class", "continue", "def", "del", "elif", "else", "except",
	"finally", "for", "from", "global", "if", "import", "in", "is",
	"lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try",
	"while", "with", "yield", "print", "input", "len", "range", "int",
	"str", "float", "bool", "list", "dict", "set", "tuple"
]


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_code_editor()
	_connect_signals()
	_setup_syntax_highlighting()

	if not starter_code.is_empty():
		code_edit.text = starter_code


# ==================== 公共方法 ====================
## 设置课程内容
func set_lesson(lesson_data: Dictionary) -> void:
	lesson_id = lesson_data.get("id", "")
	task_description = lesson_data.get("description", "")
	starter_code = lesson_data.get("starter_code", "")
	_hints = lesson_data.get("hints", [])
	_validation_rules = lesson_data.get("validation", {})

	# 更新UI
	title_label.text = lesson_data.get("title", "代码编辑器")
	task_label.text = task_description
	code_edit.text = starter_code
	output_label.text = ""
	status_label.text = ""
	progress_bar.visible = false

	_current_hint_index = 0


## 获取当前代码
func get_code() -> String:
	return code_edit.text


## 设置代码
func set_code(code: String) -> void:
	code_edit.text = code


## 清空代码
func clear_code() -> void:
	code_edit.text = starter_code
	output_label.text = ""
	status_label.text = ""


## 显示输出
func show_output(text: String, is_error: bool = false) -> void:
	if is_error:
		output_label.text = "[color=red]%s[/color]" % text
	else:
		output_label.text = "[color=green]%s[/color]" % text


## 显示执行中状态
func show_loading() -> void:
	_is_running = true
	progress_bar.visible = true
	progress_bar.value = 0
	status_label.text = "执行中..."
	run_button.disabled = true
	submit_button.disabled = true

	# 动画效果
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(progress_bar, "value", 100, 1.0)
	tween.tween_property(progress_bar, "value", 0, 0.0)


## 隐藏加载状态
func hide_loading() -> void:
	_is_running = false
	progress_bar.visible = false
	run_button.disabled = false
	submit_button.disabled = false


## 显示下一个提示
func show_next_hint() -> void:
	if _hints.is_empty():
		output_label.text = "[color=yellow]没有更多提示了[/color]"
		return

	if _current_hint_index >= _hints.size():
		output_label.text = "[color=yellow]已经显示所有提示[/color]"
		return

	var hint := _hints[_current_hint_index]
	output_label.text = "[color=cyan]提示 %d: %s[/color]" % [_current_hint_index + 1, hint]
	_current_hint_index += 1


# ==================== 私有方法 ====================
func _setup_code_editor() -> void:
	# 配置TextEdit
	code_edit.syntax_highlighter = CodeHighlighter.new()
	code_edit.minimap_draw = true
	code_edit.draw_line_numbers = true
	code_edit.draw_tabs = true
	code_edit.draw_spaces = false
	code_edit.indent_size = 4
	code_edit.auto_indent = true
	code_edit.indent_automatic = true
	code_edit.deselect_on_focus_loss = true
	code_edit.drag_and_drop_selection_enabled = true

	# 设置字体
	var font := ThemeDB.fallback_font
	code_edit.add_theme_font_override("font", font)
	code_edit.add_theme_font_size_override("font_size", 16)


func _connect_signals() -> void:
	run_button.pressed.connect(_on_run_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	close_button.pressed.connect(_on_close_pressed)
	code_edit.text_changed.connect(_on_text_changed)

	PythonExecutor.execution_completed.connect(_on_execution_completed)
	PythonExecutor.validation_passed.connect(_on_validation_passed)
	PythonExecutor.validation_failed.connect(_on_validation_failed)


func _setup_syntax_highlighting() -> void:
	var highlighter: CodeHighlighter = code_edit.syntax_highlighter

	# 关键词颜色
	for keyword in PYTHON_KEYWORDS:
		highlighter.add_keyword_color(keyword, Color("#569cd6"))  # 蓝色

	# 数字颜色
	highlighter.number_color = Color("#b5cea8")  # 绿色

	# 字符串颜色
	highlighter.string_color = Color("#ce9178")  # 橙色

	# 注释颜色
	highlighter.comment_color = Color("#6a9955")  # 绿色

	# 函数颜色
	highlighter.function_color = Color("#dcdcaa")  # 黄色

	# 成员变量颜色
	highlighter.member_variable_color = Color("#9cdcfe")  # 浅蓝


# ==================== 信号处理 ====================
func _on_run_pressed() -> void:
	if _is_running:
		return

	_current_code = code_edit.text
	show_loading()

	# 执行代码
	var result := await PythonExecutor.execute(_current_code)
	hide_loading()

	if result.success:
		show_output(result.output)
		status_label.text = "执行成功"
	else:
		show_output(result.error, true)
		status_label.text = "执行失败"


func _on_submit_pressed() -> void:
	if _is_running:
		return

	_current_code = code_edit.text
	show_loading()
	status_label.text = "验证中..."

	# 验证代码
	var is_valid := await PythonExecutor.validate(_current_code, lesson_id, _validation_rules)
	hide_loading()

	emit_signal("code_submitted", _current_code)
	emit_signal("code_validated", is_valid)


func _on_hint_pressed() -> void:
	show_next_hint()
	emit_signal("hint_requested")


func _on_clear_pressed() -> void:
	clear_code()


func _on_close_pressed() -> void:
	emit_signal("close_requested")
	hide()


func _on_text_changed() -> void:
	# 可以在这里添加实时语法检查
	pass


func _on_execution_completed(result: Dictionary) -> void:
	hide_loading()
	if result.success:
		show_output(result.output)
	else:
		show_output(result.error, true)


func _on_validation_passed(validated_lesson_id: String) -> void:
	if validated_lesson_id == lesson_id:
		status_label.text = "验证通过！"
		status_label.add_theme_color_override("font_color", Color.GREEN)


func _on_validation_failed(failed_lesson_id: String, errors: Array) -> void:
	if failed_lesson_id == lesson_id:
		status_label.text = "验证失败"
		status_label.add_theme_color_override("font_color", Color.RED)

		var error_text := "\n".join(errors)
		show_output(error_text, true)
