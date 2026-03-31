## 任务系统 - 核心系统
## 负责任务的管理、追踪和完成
class_name QuestSystem
extends Node

# ==================== 信号 ====================
signal quest_accepted(quest_id: String)
signal quest_updated(quest_id: String, progress: int)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String, reason: String)
signal objective_completed(quest_id: String, objective_index: int)

# ==================== 常量 ====================
const QUEST_DATA_PATH := "res://data/quests/"

# ==================== 枚举 ====================
enum QuestState {
	LOCKED,      ## 未解锁
	AVAILABLE,   ## 可接受
	ACTIVE,      ## 进行中
	COMPLETED,   ## 已完成
	FAILED       ## 失败
}

# ==================== 数据类 ====================
class QuestObjective:
	var description: String = ""
	var is_completed: bool = false
	var current_progress: int = 0
	var required_progress: int = 1

	func is_objective_complete() -> bool:
		return current_progress >= required_progress


class QuestData:
	var id: String = ""
	var title: String = ""
	var description: String = ""
	var chapter: int = 1
	var state: QuestState = QuestState.LOCKED
	var objectives: Array[QuestObjective] = []
	var rewards: Dictionary = {}
	var prerequisites: Array[String] = []
	var time_limit: float = -1.0  # -1表示无限制
	var is_main_quest: bool = false
	var npc_giver: String = ""

# ==================== 变量 ====================
var _quests: Dictionary = {}  # {quest_id: QuestData}
var _active_quests: Array[String] = []
var _completed_quests: Array[String] = []


# ==================== 生命周期 ====================
func _ready() -> void:
	print("[QuestSystem] 初始化任务系统...")
	_load_all_quests()


# ==================== 公共方法 ====================
## 接受任务
func accept_quest(quest_id: String) -> bool:
	if not _quests.has(quest_id):
		push_warning("[QuestSystem] 任务不存在: %s" % quest_id)
		return false

	var quest: QuestData = _quests[quest_id]

	if quest.state != QuestState.AVAILABLE:
		push_warning("[QuestSystem] 任务不可接受: %s (状态: %d)" % [quest_id, quest.state])
		return false

	# 检查前置任务
	if not _check_prerequisites(quest):
		push_warning("[QuestSystem] 前置任务未完成: %s" % quest_id)
		return false

	quest.state = QuestState.ACTIVE
	_active_quests.append(quest_id)

	emit_signal("quest_accepted", quest_id)
	print("[QuestSystem] 接受任务: %s" % quest_id)
	return true


## 更新任务进度
func update_progress(quest_id: String, objective_index: int, progress: int) -> bool:
	if not _quests.has(quest_id):
		return false

	var quest: QuestData = _quests[quest_id]

	if quest.state != QuestState.ACTIVE:
		return false

	if objective_index < 0 or objective_index >= quest.objectives.size():
		return false

	var objective: QuestObjective = quest.objectives[objective_index]
	objective.current_progress = mini(objective.current_progress + progress, objective.required_progress)

	emit_signal("quest_updated", quest_id, objective.current_progress)

	# 检查目标是否完成
	if objective.is_objective_complete() and not objective.is_completed:
		objective.is_completed = true
		emit_signal("objective_completed", quest_id, objective_index)

		# 检查整个任务是否完成
		if _check_quest_completion(quest):
			_complete_quest(quest_id)

	return true


## 设置目标进度（直接设置而非累加）
func set_progress(quest_id: String, objective_index: int, progress: int) -> bool:
	if not _quests.has(quest_id):
		return false

	var quest: QuestData = _quests[quest_id]

	if quest.state != QuestState.ACTIVE:
		return false

	if objective_index < 0 or objective_index >= quest.objectives.size():
		return false

	var objective: QuestObjective = quest.objectives[objective_index]
	objective.current_progress = clampi(progress, 0, objective.required_progress)

	emit_signal("quest_updated", quest_id, objective.current_progress)

	if objective.is_objective_complete() and not objective.is_completed:
		objective.is_completed = true
		emit_signal("objective_completed", quest_id, objective_index)

		if _check_quest_completion(quest):
			_complete_quest(quest_id)

	return true


## 完成任务
func complete_quest(quest_id: String) -> bool:
	if not _quests.has(quest_id):
		return false

	var quest: QuestData = _quests[quest_id]

	if quest.state != QuestState.ACTIVE:
		return false

	# 强制完成所有目标
	for objective in quest.objectives:
		objective.current_progress = objective.required_progress
		objective.is_completed = true

	_complete_quest(quest_id)
	return true


## 放弃任务
func abandon_quest(quest_id: String) -> bool:
	if not _quests.has(quest_id):
		return false

	var quest: QuestData = _quests[quest_id]

	if quest.state != QuestState.ACTIVE:
		return false

	quest.state = QuestState.AVAILABLE
	_active_quests.erase(quest_id)

	# 重置目标进度
	for objective in quest.objectives:
		objective.current_progress = 0
		objective.is_completed = false

	print("[QuestSystem] 放弃任务: %s" % quest_id)
	return true


## 获取任务数据
func get_quest(quest_id: String) -> QuestData:
	return _quests.get(quest_id)


## 获取所有活动任务
func get_active_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for quest_id in _active_quests:
		if _quests.has(quest_id):
			result.append(_quests[quest_id])
	return result


## 获取章节任务
func get_chapter_quests(chapter: int) -> Array[QuestData]:
	var result: Array[QuestData] = []
	for quest_id in _quests.keys():
		var quest: QuestData = _quests[quest_id]
		if quest.chapter == chapter:
			result.append(quest)
	return result


## 检查任务是否完成
func is_quest_completed(quest_id: String) -> bool:
	return quest_id in _completed_quests


## 检查任务是否活动
func is_quest_active(quest_id: String) -> bool:
	return quest_id in _active_quests


## 解锁任务
func unlock_quest(quest_id: String) -> bool:
	if not _quests.has(quest_id):
		return false

	var quest: QuestData = _quests[quest_id]

	if quest.state == QuestState.LOCKED:
		quest.state = QuestState.AVAILABLE
		print("[QuestSystem] 解锁任务: %s" % quest_id)
		return true

	return false


## 获取任务完成百分比
func get_completion_percentage() -> float:
	var total := _quests.size()
	if total == 0:
		return 0.0

	var completed := _completed_quests.size()
	return float(completed) / float(total) * 100.0


## 获取章节完成百分比
func get_chapter_completion_percentage(chapter: int) -> float:
	var chapter_quests := get_chapter_quests(chapter)
	if chapter_quests.is_empty():
		return 0.0

	var completed := 0
	for quest in chapter_quests:
		if quest.state == QuestState.COMPLETED:
			completed += 1

	return float(completed) / float(chapter_quests.size()) * 100.0


# ==================== 私有方法 ====================
func _load_all_quests() -> void:
	# 加载所有任务数据文件
	var dir := DirAccess.open(QUEST_DATA_PATH)
	if dir == null:
		push_warning("[QuestSystem] 无法打开任务数据目录")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".json"):
			var file_path := QUEST_DATA_PATH + file_name
			_load_quest_file(file_path)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("[QuestSystem] 加载了 %d 个任务" % _quests.size())


func _load_quest_file(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[QuestSystem] 无法读取任务文件: %s" % file_path)
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		push_error("[QuestSystem] 任务文件解析失败: %s" % file_path)
		return

	var data: Dictionary = json.data
	var quest := _parse_quest_data(data)

	if quest:
		_quests[quest.id] = quest


func _parse_quest_data(data: Dictionary) -> QuestData:
	var quest := QuestData.new()
	quest.id = data.get("id", "")
	quest.title = data.get("title", "未知任务")
	quest.description = data.get("description", "")
	quest.chapter = data.get("chapter", 1)
	quest.is_main_quest = data.get("is_main_quest", false)
	quest.npc_giver = data.get("npc_giver", "")
	quest.time_limit = data.get("time_limit", -1.0)
	quest.prerequisites = data.get("prerequisites", [])
	quest.rewards = data.get("rewards", {})

	# 解析目标
	var objectives_data: Array = data.get("objectives", [])
	for obj_data in objectives_data:
		var objective := QuestObjective.new()
		objective.description = obj_data.get("description", "")
		objective.required_progress = obj_data.get("required_progress", 1)
		objective.current_progress = obj_data.get("current_progress", 0)
		quest.objectives.append(objective)

	# 设置初始状态
	var initial_state: String = data.get("initial_state", "available")
	match initial_state:
		"locked":
			quest.state = QuestState.LOCKED
		"available":
			quest.state = QuestState.AVAILABLE
		"active":
			quest.state = QuestState.ACTIVE
		_:
			quest.state = QuestState.AVAILABLE

	return quest


func _check_prerequisites(quest: QuestData) -> bool:
	for prereq_id in quest.prerequisites:
		if prereq_id not in _completed_quests:
			return false
	return true


func _check_quest_completion(quest: QuestData) -> bool:
	for objective in quest.objectives:
		if not objective.is_objective_complete():
			return false
	return true


func _complete_quest(quest_id: String) -> void:
	var quest: QuestData = _quests[quest_id]
	quest.state = QuestState.COMPLETED
	_active_quests.erase(quest_id)
	_completed_quests.append(quest_id)

	# 发放奖励
	_grant_rewards(quest.rewards)

	emit_signal("quest_completed", quest_id)
	print("[QuestSystem] 完成任务: %s" % quest_id)

	# 检查解锁新任务
	_check_quest_unlocks()


func _grant_rewards(rewards: Dictionary) -> void:
	# 经验值
	if rewards.has("xp"):
		var xp: int = rewards.xp
		GameManager.player_data.add_xp(xp)
		print("[QuestSystem] 获得经验: %d" % xp)

	# 物品
	if rewards.has("items"):
		var items: Dictionary = rewards.items
		for item_id in items.keys():
			var count: int = items[item_id]
			GameManager.player_data.add_item(item_id, count)
			print("[QuestSystem] 获得物品: %s x%d" % [item_id, count])

	# 成就
	if rewards.has("achievement"):
		var achievement_id: String = rewards.achievement
		if GameManager.player_data.unlock_achievement(achievement_id):
			print("[QuestSystem] 解锁成就: %s" % achievement_id)


func _check_quest_unlocks() -> void:
	for quest_id in _quests.keys():
		var quest: QuestData = _quests[quest_id]
		if quest.state == QuestState.LOCKED:
			if _check_prerequisites(quest):
				unlock_quest(quest_id)


## 从存档恢复任务状态
func load_from_save(save_data: Dictionary) -> void:
	var completed: Array = save_data.get("completed_quests", [])
	for quest_id in completed:
		if _quests.has(quest_id):
			var quest: QuestData = _quests[quest_id]
			quest.state = QuestState.COMPLETED
			_completed_quests.append(quest_id)

	var active: Array = save_data.get("active_quests", [])
	for quest_id in active:
		if _quests.has(quest_id):
			var quest: QuestData = _quests[quest_id]
			quest.state = QuestState.ACTIVE
			_active_quests.append(quest_id)


## 获取存档数据
func get_save_data() -> Dictionary:
	return {
		"completed_quests": _completed_quests,
		"active_quests": _active_quests
	}
