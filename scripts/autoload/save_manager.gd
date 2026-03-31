## 存档管理器 - 核心单例
## 负责游戏存档的读取、写入和管理
class_name SaveManager
extends Node

# ==================== 信号 ====================
signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_deleted(slot: int)
signal auto_save_triggered()

# ==================== 常量 ====================
const SAVE_PATH := "user://saves/"
const SETTINGS_PATH := "user://settings.cfg"
const MAX_SAVE_SLOTS := 3
const AUTO_SAVE_INTERVAL := 300.0  # 5分钟自动保存

# ==================== 变量 ====================
var _auto_save_timer: float = 0.0
var _is_auto_save_enabled: bool = true


# ==================== 生命周期 ====================
func _ready() -> void:
	print("[SaveManager] 初始化存档管理器...")
	_ensure_save_directory()
	_load_settings()


func _process(delta: float) -> void:
	if _is_auto_save_enabled and GameManager.current_state == GameManager.GameState.PLAYING:
		_auto_save_timer += delta
		if _auto_save_timer >= AUTO_SAVE_INTERVAL:
			_auto_save_timer = 0.0
			auto_save()


# ==================== 存档操作 ====================
## 保存游戏
func save(slot: int, player_data: PlayerData) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] 无效的存档槽位: %d" % slot)
		emit_signal("save_completed", slot, false)
		return false

	var save_data := _create_save_data(player_data)
	var file_path := _get_save_path(slot)

	# 写入文件
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] 无法创建存档文件: %s" % file_path)
		emit_signal("save_completed", slot, false)
		return false

	var json_string := JSON.stringify(save_data, "  ")
	file.store_string(json_string)
	file.close()

	# 同时保存缩略图
	_save_thumbnail(slot)

	emit_signal("save_completed", slot, true)
	print("[SaveManager] 存档保存成功: 槽位 %d" % slot)
	return true


## 加载游戏
func load(slot: int) -> PlayerData:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] 无效的存档槽位: %d" % slot)
		emit_signal("load_completed", slot, false)
		return null

	var file_path := _get_save_path(slot)

	if not FileAccess.file_exists(file_path):
		push_warning("[SaveManager] 存档不存在: %s" % file_path)
		emit_signal("load_completed", slot, false)
		return null

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] 无法读取存档文件: %s" % file_path)
		emit_signal("load_completed", slot, false)
		return null

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("[SaveManager] 存档文件解析失败: %s" % json.get_error_message())
		emit_signal("load_completed", slot, false)
		return null

	var player_data := _parse_save_data(json.data)
	emit_signal("load_completed", slot, true)
	print("[SaveManager] 存档加载成功: 槽位 %d" % slot)
	return player_data


## 删除存档
func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false

	var file_path := _get_save_path(slot)
	var thumbnail_path := _get_thumbnail_path(slot)

	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

	if FileAccess.file_exists(thumbnail_path):
		DirAccess.remove_absolute(thumbnail_path)

	emit_signal("save_deleted", slot)
	print("[SaveManager] 存档已删除: 槽位 %d" % slot)
	return true


## 自动保存
func auto_save() -> bool:
	if GameManager.player_data == null:
		return false

	# 自动保存使用特殊槽位
	var success := save(-1, GameManager.player_data)
	if success:
		emit_signal("auto_save_triggered")
		print("[SaveManager] 自动保存完成")
	return success


## 检查存档是否存在
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))


## 获取存档列表
func get_all_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []

	for slot in range(MAX_SAVE_SLOTS):
		if has_save(slot):
			saves.append({
				"slot": slot,
				"info": get_save_info(slot)
			})

	return saves


## 获取存档信息
func get_save_info(slot: int) -> Dictionary:
	var file_path := _get_save_path(slot)

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
		"lesson": data.get("current_lesson", ""),
		"xp": data.get("total_xp", 0),
		"level": data.get("total_xp", 0) / 500 + 1,
		"save_time": data.get("last_save_time", "未知时间"),
		"play_time": _format_play_time(data.get("total_play_time", 0)),
		"completed_lessons": data.get("completed_lessons", []).size()
	}


# ==================== 设置相关 ====================
## 保存设置
func save_settings(settings: Dictionary) -> bool:
	var config := ConfigFile.new()

	for section in settings.keys():
		var section_data: Dictionary = settings[section]
		for key in section_data.keys():
			config.set_value(section, key, section_data[key])

	var error := config.save(SETTINGS_PATH)
	return error == OK


## 加载设置
func load_settings() -> Dictionary:
	var config := ConfigFile.new()
	var settings: Dictionary = {}

	if config.load(SETTINGS_PATH) != OK:
		return _get_default_settings()

	for section in config.get_sections():
		settings[section] = {}
		for key in config.get_section_keys(section):
			settings[section][key] = config.get_value(section, key)

	return settings


## 重置设置
func reset_settings() -> void:
	var default_settings := _get_default_settings()
	save_settings(default_settings)


# ==================== 私有方法 ====================
func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


func _get_save_path(slot: int) -> String:
	if slot == -1:
		return SAVE_PATH + "auto_save.save"
	return SAVE_PATH + "slot_%d.save" % slot


func _get_thumbnail_path(slot: int) -> String:
	if slot == -1:
		return SAVE_PATH + "auto_save.png"
	return SAVE_PATH + "slot_%d.png" % slot


func _create_save_data(player_data: PlayerData) -> Dictionary:
	return {
		"version": ProjectSettings.get_setting("application/config/version", "0.2.0"),
		"save_time": Time.get_datetime_string_from_system(),
		"player_name": player_data.player_name,
		"current_chapter": player_data.current_chapter,
		"current_lesson": player_data.current_lesson,
		"completed_lessons": player_data.completed_lessons,
		"unlocked_chapters": player_data.unlocked_chapters,
		"total_xp": player_data.total_xp,
		"total_play_time": player_data.total_play_time,
		"inventory": player_data.inventory,
		"achievements": player_data.achievements,
		"npc_relationships": player_data.npc_relationships,
		"triggered_dialogues": player_data.triggered_dialogues,
		"settings": {
			"bgm_volume": player_data.bgm_volume,
			"sfx_volume": player_data.sfx_volume,
			"language": player_data.language,
			"editor_theme": player_data.editor_theme
		}
	}


func _parse_save_data(data: Dictionary) -> PlayerData:
	var player_data := PlayerData.new()

	player_data.player_name = data.get("player_name", "旅行者")
	player_data.current_chapter = data.get("current_chapter", 1)
	player_data.current_lesson = data.get("current_lesson", "lesson_1_1")
	player_data.completed_lessons = data.get("completed_lessons", [])
	player_data.unlocked_chapters = data.get("unlocked_chapters", [1])
	player_data.total_xp = data.get("total_xp", 0)
	player_data.total_play_time = data.get("total_play_time", 0.0)
	player_data.inventory = data.get("inventory", {})
	player_data.achievements = data.get("achievements", [])
	player_data.npc_relationships = data.get("npc_relationships", {})
	player_data.triggered_dialogues = data.get("triggered_dialogues", [])

	var settings: Dictionary = data.get("settings", {})
	player_data.bgm_volume = settings.get("bgm_volume", 1.0)
	player_data.sfx_volume = settings.get("sfx_volume", 1.0)
	player_data.language = settings.get("language", "zh_CN")
	player_data.editor_theme = settings.get("editor_theme", "dark")

	return player_data


func _save_thumbnail(slot: int) -> void:
	# 等待实现截图功能
	# 需要等待视口渲染完成后截取
	pass


func _load_settings() -> void:
	var settings := load_settings()
	# 应用设置
	if settings.has("audio"):
		var audio: Dictionary = settings.audio
		if audio.has("bgm_volume"):
			AudioManager.set_bgm_volume(audio.bgm_volume)
		if audio.has("sfx_volume"):
			AudioManager.set_sfx_volume(audio.sfx_volume)


func _get_default_settings() -> Dictionary:
	return {
		"audio": {
			"bgm_volume": 1.0,
			"sfx_volume": 1.0,
			"master_volume": 1.0
		},
		"display": {
			"fullscreen": false,
			"vsync": true
		},
		"gameplay": {
			"auto_save": true,
			"show_hints": true,
			"difficulty": "normal"
		},
		"language": {
			"locale": "zh_CN"
		}
	}


func _format_play_time(seconds: float) -> String:
	var hours := int(seconds / 3600)
	var minutes := int((seconds - hours * 3600) / 60)
	return "%d小时%d分钟" % [hours, minutes]
