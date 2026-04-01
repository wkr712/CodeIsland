## 课程面板 - UI脚本
## 显示课程列表和学习进度
class_name LessonPanel
extends Control

# ==================== 信号 ====================
signal lesson_selected(lesson_id: String)
signal chapter_changed(chapter: int)
signal panel_closed()

# ==================== 导出变量 ====================
## 当前章节
@export var current_chapter: int = 1

# ==================== 节点引用 ====================
@onready var chapter_title: Label = $Panel/MarginContainer/VBox/ChapterHeader/ChapterTitle
@onready var chapter_desc: RichTextLabel = $Panel/MarginContainer/VBox/ChapterHeader/ChapterDesc
@onready var progress_bar: ProgressBar = $Panel/MarginContainer/VBox/ChapterHeader/ProgressBar
@onready var lessons_container: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/LessonsContainer
@onready var prev_chapter_btn: Button = $Panel/MarginContainer/VBox/Navigation/PrevChapter
@onready var next_chapter_btn: Button = $Panel/MarginContainer/VBox/Navigation/NextChapter
@onready var close_btn: Button = $Panel/MarginContainer/VBox/Header/CloseBtn

# ==================== 变量 ====================
var _lessons_data: Array[Dictionary] = []
var _lesson_buttons: Array[Button] = []


# ==================== 生命周期 ====================
func _ready() -> void:
	_connect_signals()
	_load_chapter_data(current_chapter)


# ==================== 公共方法 ====================
## 设置当前章节
func set_chapter(chapter: int) -> void:
	current_chapter = chapter
	_load_chapter_data(chapter)
	emit_signal("chapter_changed", chapter)


## 刷新显示
func refresh() -> void:
	_load_chapter_data(current_chapter)


# ==================== 私有方法 ====================
func _connect_signals() -> void:
	if prev_chapter_btn:
		prev_chapter_btn.pressed.connect(_on_prev_chapter)
	if next_chapter_btn:
		next_chapter_btn.pressed.connect(_on_next_chapter)
	if close_btn:
		close_btn.pressed.connect(_on_close)


func _load_chapter_data(chapter: int) -> void:
	var file_path := "res://data/lessons/chapter_%d.json" % chapter

	if not ResourceLoader.exists(file_path):
		push_error("[LessonPanel] 课程文件不存在: %s" % file_path)
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return

	var data: Dictionary = json.data

	# 更新章节标题
	if chapter_title:
		chapter_title.text = "第%d章: %s" % [chapter, data.get("chapter_title", "")]

	if chapter_desc:
		chapter_desc.text = data.get("chapter_description", "")

	# 加载课程列表
	_lessons_data = []
	var lessons: Array = data.get("lessons", [])
	for lesson in lessons:
		_lessons_data.append(lesson)

	# 更新进度条
	_update_progress()

	# 显示课程列表
	_display_lessons()

	# 更新导航按钮
	_update_navigation()


func _update_progress() -> void:
	var completed := 0
	var total := _lessons_data.size()

	for lesson in _lessons_data:
		var lesson_id: String = lesson.get("id", "")
		if GameManager.player_data.is_lesson_completed(lesson_id):
			completed += 1

	if progress_bar:
		progress_bar.max_value = total
		progress_bar.value = completed

		if total > 0:
			progress_bar.tooltip_text = "完成进度: %d/%d" % [completed, total]


func _display_lessons() -> void:
	# 清除旧按钮
	for btn in _lesson_buttons:
		btn.queue_free()
	_lesson_buttons.clear()

	if lessons_container == null:
		return

	# 创建课程按钮
	for i in _lessons_data.size():
		var lesson: Dictionary = _lessons_data[i]
		var btn := Button.new()

		var lesson_id: String = lesson.get("id", "")
		var title: String = lesson.get("title", "未知课程")
		var xp: int = lesson.get("xp_reward", 100)
		var is_completed := GameManager.player_data.is_lesson_completed(lesson_id)

		# 按钮文本
		var status_icon := "✓" if is_completed else "○"
		btn.text = "%s %s (%d XP)" % [status_icon, title, xp]

		# 样式
		if is_completed:
			btn.modulate = Color(0.5, 1.0, 0.5)  # 绿色表示完成
		elif i == 0 or GameManager.player_data.is_lesson_completed(_lessons_data[i-1].get("id", "")):
			btn.modulate = Color(1.0, 1.0, 1.0)  # 白色表示可学习
		else:
			btn.modulate = Color(0.5, 0.5, 0.5)  # 灰色表示锁定
			btn.disabled = true

		btn.pressed.connect(_on_lesson_selected.bind(lesson_id))
		lessons_container.add_child(btn)
		_lesson_buttons.append(btn)


func _update_navigation() -> void:
	# 上一章按钮
	if prev_chapter_btn:
		prev_chapter_btn.disabled = current_chapter <= 1

	# 下一章按钮
	if next_chapter_btn:
		var next_chapter := current_chapter + 1
		var next_file := "res://data/lessons/chapter_%d.json" % next_chapter
		var chapter_unlocked := GameManager.player_data.is_chapter_unlocked(next_chapter)
		next_chapter_btn.disabled = not ResourceLoader.exists(next_file) or not chapter_unlocked


# ==================== 信号处理 ====================
func _on_lesson_selected(lesson_id: String) -> void:
	emit_signal("lesson_selected", lesson_id)
	hide()


func _on_prev_chapter() -> void:
	if current_chapter > 1:
		set_chapter(current_chapter - 1)


func _on_next_chapter() -> void:
	var next_chapter := current_chapter + 1
	if GameManager.player_data.is_chapter_unlocked(next_chapter):
		set_chapter(next_chapter)


func _on_close() -> void:
	emit_signal("panel_closed")
	hide()
