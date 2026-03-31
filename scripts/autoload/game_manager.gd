## 游戏管理器 - 核心单例
## 负责游戏状态管理、场景切换、玩家数据
class_name GameManager
extends Node

# ==================== 信号 ====================
signal game_started
signal game_paused
signal game_resumed
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal scene_changed(scene_name: String)
signal chapter_unlocked(chapter: int)
signal lesson_completed(lesson_id: String)

# ==================== 常量 ====================
const MAX_SAVE_SLOTS := 3
const SAVE_PATH := "user://saves/"

# ==================== 枚举 ====================
enum GameState {
	MENU,        ## 主菜单
	PLAYING,     ## 游戏中
	PAUSED,      ## 暂停
	DIALOGUE,    ## 对话中
	CODING,      ## 编码界面
	CUTSCENE     ## 过场动画
}

# ==================== 变量 ====================
var current_state: GameState = GameState.MENU
var previous_state: GameState = GameState.MENU
var current_scene_path: String = ""
var current_chapter: int = 1
var is_transitioning: bool = false

# 玩家数据
var player_data: PlayerData


# ==================== 生命周期 ====================
func _ready() -> void:
	print("[GameManager] 初始化游戏管理器...")
	player_data = PlayerData.new()
	_ensure_save_directory()


# ==================== 公共方法 ====================
## 开始新游戏
func start_new_game() -> void:
	print("[GameManager] 开始新游戏")
	player_data = PlayerData.new()
	player_data.player_name = "旅行者"
	player_data.current_chapter = 1
	player_data.current_lesson = "lesson_1_1"

	current_state = GameState.PLAYING
	emit_signal("game_started")

	# 切换到游戏场景
	change_scene("res://scenes/world/village.tscn")


## 继续游戏（加载最近存档）
func continue_game() -> bool:
	var latest_slot := _get_latest_save_slot()
	if latest_slot < 0:
		push_warning("[GameManager] 没有找到存档")
		return false

	return load_game(latest_slot)


## 保存游戏
func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[GameManager] 无效的存档槽位: %d" % slot)
		return false

	var save_data := _create_save_data()
	var file_path := SAVE_PATH + "slot_%d.save" % slot

	var error := FileAccess.open(file_path, FileAccess.WRITE)
	if error == null:
		push_error("[GameManager] 无法创建存档文件: %s" % file_path)
		return false

	var json_string := JSON.stringify(save_data)
	error.store_string(json_string)
	error.close()

	player_data.last_save_time = Time.get_datetime_string_from_system()
	emit_signal("game_saved", slot)
	print("[GameManager] 游戏已保存到槽位 %d" % slot)
	return true


## 加载游戏
func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[GameManager] 无效的存档槽位: %d" % slot)
		return false

	var file_path := SAVE_PATH + "slot_%d.save" % slot

	if not FileAccess.file_exists(file_path):
		push_warning("[GameManager] 存档不存在: %s" % file_path)
		return false

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[GameManager] 无法读取存档文件: %s" % file_path)
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("[GameManager] 存档文件解析失败")
		return false

	_load_save_data(json.data)
	emit_signal("game_loaded", slot)

	current_state = GameState.PLAYING
	print("[GameManager] 已加载存档槽位 %d" % slot)
	return true


## 暂停游戏
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		previous_state = current_state
		current_state = GameState.PAUSED
		get_tree().paused = true
		emit_signal("game_paused")
		print("[GameManager] 游戏已暂停")


## 恢复游戏
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = previous_state
		get_tree().paused = false
		emit_signal("game_resumed")
		print("[GameManager] 游戏已恢复")


## 切换游戏状态
func set_state(new_state: GameState) -> void:
	previous_state = current_state
	current_state = new_state


## 切换场景
func change_scene(scene_path: String) -> void:
	if is_transitioning:
		return

	is_transitioning = true
	current_scene_path = scene_path

	# 使用淡入淡出效果切换场景
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("[GameManager] 场景切换失败: %s" % scene_path)
		is_transitioning = false
		return

	emit_signal("scene_changed", scene_path)
	is_transitioning = false


## 完成课程
func complete_lesson(lesson_id: String) -> void:
	if lesson_id not in player_data.completed_lessons:
		player_data.completed_lessons.append(lesson_id)
		player_data.total_xp += 100  # 每课100经验

		# 检查是否解锁新章节
		_check_chapter_unlock()

		emit_signal("lesson_completed", lesson_id)
		print("[GameManager] 完成课程: %s" % lesson_id)


## 解锁章节
func unlock_chapter(chapter: int) -> void:
	if chapter not in player_data.unlocked_chapters:
		player_data.unlocked_chapters.append(chapter)
		emit_signal("chapter_unlocked", chapter)
		print("[GameManager] 解锁章节: %d" % chapter)


## 获取存档信息
func get_save_info(slot: int) -> Dictionary:
	var file_path := SAVE_PATH + "slot_%d.save" % slot

	if not FileAccess.file_exists(file_path):
		return {}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var data: Dictionary = json.data
	return {
		"player_name": data.get("player_name", "未知"),
		"chapter": data.get("current_chapter", 1),
		"xp": data.get("total_xp", 0),
		"save_time": data.get("last_save_time", ""),
		"play_time": data.get("total_play_time", 0)
	}


## 检查存档是否存在
func has_save(slot: int) -> bool:
	var file_path := SAVE_PATH + "slot_%d.save" % slot
	return FileAccess.file_exists(file_path)


# ==================== 私有方法 ====================
func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("[GameManager] 创建存档目录")


func _create_save_data() -> Dictionary:
	return {
		"version": ProjectSettings.get_setting("application/config/version", "0.2.0"),
		"player_name": player_data.player_name,
		"current_chapter": player_data.current_chapter,
		"current_lesson": player_data.current_lesson,
		"completed_lessons": player_data.completed_lessons,
		"unlocked_chapters": player_data.unlocked_chapters,
		"total_xp": player_data.total_xp,
		"inventory": player_data.inventory,
		"achievements": player_data.achievements,
		"last_save_time": Time.get_datetime_string_from_system(),
		"total_play_time": player_data.total_play_time,
		"settings": {
			"bgm_volume": player_data.bgm_volume,
			"sfx_volume": player_data.sfx_volume,
			"language": player_data.language
		}
	}


func _load_save_data(data: Dictionary) -> void:
	player_data.player_name = data.get("player_name", "旅行者")
	player_data.current_chapter = data.get("current_chapter", 1)
	player_data.current_lesson = data.get("current_lesson", "lesson_1_1")
	player_data.completed_lessons = data.get("completed_lessons", [])
	player_data.unlocked_chapters = data.get("unlocked_chapters", [1])
	player_data.total_xp = data.get("total_xp", 0)
	player_data.inventory = data.get("inventory", {})
	player_data.achievements = data.get("achievements", [])

	var settings: Dictionary = data.get("settings", {})
	player_data.bgm_volume = settings.get("bgm_volume", 1.0)
	player_data.sfx_volume = settings.get("sfx_volume", 1.0)
	player_data.language = settings.get("language", "zh_CN")


func _get_latest_save_slot() -> int:
	var latest_slot := -1
	var latest_time := ""

	for slot in range(MAX_SAVE_SLOTS):
		var info := get_save_info(slot)
		if info.is_empty():
			continue

		var save_time: String = info.get("save_time", "")
		if save_time > latest_time:
			latest_time = save_time
			latest_slot = slot

	return latest_slot


func _check_chapter_unlock() -> void:
	# 检查每章的解锁条件
	var chapter_lessons := {
		1: 5,   # 第1章5课
		2: 6,   # 第2章6课
		3: 5,   # 第3章5课
		4: 6,   # 第4章6课
		5: 7,   # 第5章7课
		6: 6,   # 第6章6课
		7: 5,   # 第7章5课
		8: 10   # 第8章10课
	}

	for chapter in chapter_lessons.keys():
		if chapter in player_data.unlocked_chapters:
			continue

		var required_lessons: int = chapter_lessons[chapter]
		var completed_in_chapter := 0

		for lesson_id in player_data.completed_lessons:
			if lesson_id.begins_with("lesson_%d_" % chapter):
				completed_in_chapter += 1

		if completed_in_chapter >= required_lessons:
			unlock_chapter(chapter + 1)
