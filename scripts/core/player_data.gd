## 玩家数据类
## 存储玩家的所有游戏进度数据
class_name PlayerData
extends Resource

# ==================== 基本信息 ====================
## 玩家名称
@export var player_name: String = "旅行者"

## 当前章节
@export var current_chapter: int = 1

## 当前课程ID
@export var current_lesson: String = "lesson_1_1"

# ==================== 进度数据 ====================
## 已完成的课程列表
@export var completed_lessons: Array[String] = []

## 已解锁的章节
@export var unlocked_chapters: Array[int] = [1]

## 总经验值
@export var total_xp: int = 0

## 总游戏时长（秒）
@export var total_play_time: float = 0.0

## 最后保存时间
@export var last_save_time: String = ""

# ==================== 游戏数据 ====================
## 背包物品 {item_id: count}
@export var inventory: Dictionary = {}

## 已获得成就
@export var achievements: Array[String] = []

## 与NPC的关系值 {npc_id: relationship}
@export var npc_relationships: Dictionary = {}

## 已触发的对话
@export var triggered_dialogues: Array[String] = []

# ==================== 设置 ====================
## 背景音乐音量
@export var bgm_volume: float = 1.0

## 音效音量
@export var sfx_volume: float = 1.0

## 语言设置
@export var language: String = "zh_CN"

## 代码编辑器主题
@export var editor_theme: String = "dark"


# ==================== 方法 ====================
## 重置数据
func reset() -> void:
	player_name = "旅行者"
	current_chapter = 1
	current_lesson = "lesson_1_1"
	completed_lessons.clear()
	unlocked_chapters = [1]
	total_xp = 0
	total_play_time = 0.0
	inventory.clear()
	achievements.clear()
	npc_relationships.clear()
	triggered_dialogues.clear()


## 添加物品到背包
func add_item(item_id: String, count: int = 1) -> void:
	if inventory.has(item_id):
		inventory[item_id] += count
	else:
		inventory[item_id] = count


## 移除背包物品
func remove_item(item_id: String, count: int = 1) -> bool:
	if not inventory.has(item_id):
		return false

	if inventory[item_id] <= count:
		inventory.erase(item_id)
	else:
		inventory[item_id] -= count

	return true


## 检查是否有物品
func has_item(item_id: String, count: int = 1) -> bool:
	return inventory.get(item_id, 0) >= count


## 增加NPC好感度
func add_npc_relationship(npc_id: String, value: int) -> void:
	if npc_relationships.has(npc_id):
		npc_relationships[npc_id] = maxi(npc_relationships[npc_id] + value, -100)
	else:
		npc_relationships[npc_id] = clampi(value, -100, 100)


## 获取NPC好感度
func get_npc_relationship(npc_id: String) -> int:
	return npc_relationships.get(npc_id, 0)


## 添加经验值
func add_xp(amount: int) -> void:
	total_xp += amount


## 获取等级（基于经验值）
func get_level() -> int:
	# 每500经验升一级
	return total_xp / 500 + 1


## 获取当前等级进度（0-1）
func get_level_progress() -> float:
	var current_level_xp := total_xp % 500
	return float(current_level_xp) / 500.0


## 检查课程是否完成
func is_lesson_completed(lesson_id: String) -> bool:
	return lesson_id in completed_lessons


## 检查章节是否解锁
func is_chapter_unlocked(chapter: int) -> bool:
	return chapter in unlocked_chapters


## 标记对话已触发
func mark_dialogue_triggered(dialogue_id: String) -> void:
	if dialogue_id not in triggered_dialogues:
		triggered_dialogues.append(dialogue_id)


## 检查对话是否已触发
func is_dialogue_triggered(dialogue_id: String) -> bool:
	return dialogue_id in triggered_dialogues


## 解锁成就
func unlock_achievement(achievement_id: String) -> bool:
	if achievement_id in achievements:
		return false

	achievements.append(achievement_id)
	return true


## 获取统计信息
func get_stats() -> Dictionary:
	return {
		"total_lessons": completed_lessons.size(),
		"total_chapters": unlocked_chapters.size(),
		"level": get_level(),
		"xp": total_xp,
		"play_time_hours": total_play_time / 3600.0,
		"achievements": achievements.size(),
		"items": inventory.size()
	}
