## 新手村 - 游戏场景脚本
## 负责场景初始化、NPC配置和触发器
class_name Village
extends Node2D

# ==================== 节点引用 ====================
@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var village_chief: Node = $Entities/NPCs/VillageChief
@onready var code_editor_trigger: Area2D = $Triggers/CodeEditorTrigger

# ==================== 变量 ====================
var _scene_ready: bool = false


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_scene()
	_setup_npcs()
	_setup_triggers()
	_scene_ready = true

	print("[Village] 新手村场景加载完成")


# ==================== 公共方法 ====================
## 获取玩家出生点
func get_spawn_point() -> Vector2:
	var spawn := $Entities/PlayerSpawn as Marker2D
	if spawn:
		return spawn.global_position
	return Vector2.ZERO


# ==================== 私有方法 ====================
func _setup_scene() -> void:
	# 设置相机跟随
	if player and camera:
		camera.global_position = player.global_position

	# 播放背景音乐
	AudioManager.play_bgm("village_peaceful")


func _setup_npcs() -> void:
	# 配置村长NPC
	if village_chief:
		village_chief.npc_id = "village_chief"
		village_chief.npc_name = "村长"
		village_chief.dialogue_ids = ["village_chief_intro"]
		village_chief.available_quests = ["quest_1_1"]
		village_chief.is_interactable = true


func _setup_triggers() -> void:
	# 配置代码编辑器触发器
	if code_editor_trigger:
		code_editor_trigger.body_entered.connect(_on_code_editor_trigger_entered)


# ==================== 信号处理 ====================
func _on_code_editor_trigger_entered(body: Node2D) -> void:
	if body is Player:
		# 显示代码编辑器提示
		# TODO: 显示UI提示
		pass
