## 课程管理器 - 核心系统
## 负责课程加载、进度追踪和章节解锁
class_name LessonManager
extends Node

# ==================== 信号 ====================
signal lesson_started(lesson_id: String)
signal lesson_completed(lesson_id: String, xp_earned: int)
signal chapter_completed(chapter: int)
signal chapter_unlocked(chapter: int)

# ==================== 常量 ====================
const LESSON_PATH := "res://data/lessons/"

# ==================== 变量 ====================
var _chapters: Dictionary = {}  # {chapter_num: chapter_data}
var _current_lesson: Dictionary = {}


# ==================== 生命周期 ====================
func _ready() -> void:
	print("[LessonManager] 初始化课程管理器...")
	_load_all_chapters()


# ==================== 公共方法 ====================
## 获取章节课程数据
func get_chapter_lessons(chapter: int) -> Array:
	if not _chapters.has(chapter):
		return []

	var chapter_data: Dictionary = _chapters[chapter]
	return chapter_data.get("lessons", [])


## 获取单个课程数据
func get_lesson(lesson_id: String) -> Dictionary:
	var parts := lesson_id.split("_")
	if parts.size() < 3:
		return {}

	var chapter := parts[1].to_int()
	var lessons := get_chapter_lessons(chapter)

	for lesson in lessons:
		if lesson.get("id", "") == lesson_id:
			return lesson

	return {}


## 开始课程
func start_lesson(lesson_id: String) -> bool:
	var lesson := get_lesson(lesson_id)
	if lesson.is_empty():
		push_error("[LessonManager] 课程不存在: %s" % lesson_id)
		return false

	_current_lesson = lesson
	emit_signal("lesson_started", lesson_id)

	print("[LessonManager] 开始课程: %s" % lesson.get("title", lesson_id))
	return true


## 完成课程
func complete_lesson(lesson_id: String) -> int:
	var lesson := get_lesson(lesson_id)
	if lesson.is_empty():
		return 0

	# 检查是否已完成
	if GameManager.player_data.is_lesson_completed(lesson_id):
		return 0

	# 获得经验值
	var xp: int = lesson.get("xp_reward", 100)
	GameManager.player_data.add_xp(xp)

	# 标记完成
	GameManager.player_data.completed_lessons.append(lesson_id)

	# 发送信号
	emit_signal("lesson_completed", lesson_id, xp)

	# 检查章节完成
	_check_chapter_completion(lesson_id)

	print("[LessonManager] 完成课程: %s, 获得 %d XP" % [lesson_id, xp])
	return xp


## 检查课程是否解锁
func is_lesson_unlocked(lesson_id: String) -> bool:
	var lesson := get_lesson(lesson_id)
	if lesson.is_empty():
		return false

	var parts := lesson_id.split("_")
	if parts.size() < 2:
		return false

	var chapter := parts[1].to_int()

	# 检查章节是否解锁
	if not GameManager.player_data.is_chapter_unlocked(chapter):
		return false

	# 获取章节课程列表
	var lessons := get_chapter_lessons(chapter)
	var lesson_index := -1

	for i in lessons.size():
		if lessons[i].get("id", "") == lesson_id:
			lesson_index = i
			break

	if lesson_index <= 0:
		return true  # 第一章节的第一课总是解锁的

	# 检查前一课是否完成
	var prev_lesson_id: String = lessons[lesson_index - 1].get("id", "")
	return GameManager.player_data.is_lesson_completed(prev_lesson_id)


## 获取章节进度
func get_chapter_progress(chapter: int) -> Dictionary:
	var lessons := get_chapter_lessons(chapter)
	if lessons.is_empty():
		return {"completed": 0, "total": 0, "percentage": 0.0}

	var completed := 0
	for lesson in lessons:
		var lesson_id: String = lesson.get("id", "")
		if GameManager.player_data.is_lesson_completed(lesson_id):
			completed += 1

	return {
		"completed": completed,
		"total": lessons.size(),
		"percentage": float(completed) / float(lessons.size()) * 100.0
	}


## 获取总进度
func get_total_progress() -> Dictionary:
	var total_completed := 0
	var total_lessons := 0

	for chapter in _chapters.keys():
		var progress := get_chapter_progress(chapter)
		total_completed += progress.completed
		total_lessons += progress.total

	return {
		"completed": total_completed,
		"total": total_lessons,
		"percentage": float(total_completed) / float(total_lessons) * 100.0 if total_lessons > 0 else 0.0
	}


## 获取当前课程
func get_current_lesson() -> Dictionary:
	return _current_lesson


## 获取所有章节数据
func get_all_chapters() -> Dictionary:
	return _chapters


# ==================== 私有方法 ====================
func _load_all_chapters() -> void:
	for chapter in range(1, 9):  # 假设最多8章
		var file_path := LESSON_PATH + "chapter_%d.json" % chapter

		if not ResourceLoader.exists(file_path):
			continue

		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			continue

		var json := JSON.new()
		if json.parse(file.get_as_text()) != OK:
			continue

		var data: Dictionary = json.data
		_chapters[chapter] = data

		# 默认解锁第一章
		if chapter == 1 and 1 not in GameManager.player_data.unlocked_chapters:
			GameManager.player_data.unlocked_chapters.append(1)

	print("[LessonManager] 加载了 %d 个章节" % _chapters.size())


func _check_chapter_completion(lesson_id: String) -> void:
	var parts := lesson_id.split("_")
	if parts.size() < 2:
		return

	var chapter := parts[1].to_int()
	var progress := get_chapter_progress(chapter)

	# 检查是否完成章节所有课程
	if progress.completed >= progress.total and progress.total > 0:
		emit_signal("chapter_completed", chapter)

		# 解锁下一章
		var next_chapter := chapter + 1
		if _chapters.has(next_chapter):
			if next_chapter not in GameManager.player_data.unlocked_chapters:
				GameManager.player_data.unlocked_chapters.append(next_chapter)
				emit_signal("chapter_unlocked", next_chapter)
				print("[LessonManager] 解锁第%d章" % next_chapter)
