## NPC控制器
## 负责NPC的行为、对话和任务交互
class_name NPC
extends CharacterBody2D

# ==================== 信号 ====================
signal dialogue_started(npc: NPC)
signal dialogue_ended(npc: NPC)
signal quest_offered(npc: NPC, quest_id: String)
signal interacted(player: Node)

# ==================== 枚举 ====================
enum NPCState {
	IDLE,       ## 待机
	WALKING,    ## 行走
	TALKING,    ## 对话中
	INTERACTING ## 交互中
}

enum NPCBehavior {
	STATIC,     ## 静止不动
	PATROL,     ## 巡逻
	RANDOM,     ## 随机走动
	FOLLOW      ## 跟随玩家
}

# ==================== 导出变量 ====================
## NPC唯一ID
@export var npc_id: String = ""

## NPC名称
@export var npc_name: String = "NPC"

## NPC行为类型
@export var behavior: NPCBehavior = NPCBehavior.STATIC

## 对话ID列表
@export var dialogue_ids: Array[String] = []

## 可接受的任务ID
@export var available_quests: Array[String] = []

## 是否可交互
@export var is_interactable: bool = true

## 是否面向玩家
@export var face_player_on_interact: bool = true

## 巡逻路径点（用于PATROL行为）
@export var patrol_points: Array[Vector2] = []

## 移动速度
@export var move_speed: float = 50.0

## 等待时间范围（秒）
@export var wait_time_range: Vector2 = Vector2(2.0, 5.0)

# ==================== 节点引用 ====================
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var name_label: Label = $NameLabel
@onready var exclamation: Label = $Exclamation

# ==================== 变量 ====================
var _state: NPCState = NPCState.IDLE
var _current_direction: String = "down"
var _facing_player: bool = false
var _patrol_index: int = 0
var _wait_timer: float = 0.0
var _is_waiting: bool = false
var _original_position: Vector2 = Vector2.ZERO
var _has_available_quest: bool = false


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_npc()
	_connect_signals()
	_check_available_quests()


func _physics_process(delta: float) -> void:
	match _state:
		NPCState.IDLE:
			_handle_idle_behavior(delta)
		NPCState.WALKING:
			_handle_walking_behavior(delta)

	# 应用重力或停止
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += 980 * delta

	move_and_slide()


# ==================== 公共方法 ====================
## 交互（由玩家调用）
func interact(player: Node = null) -> void:
	if not is_interactable:
		return

	_state = NPCState.TALKING
	_facing_player = true

	# 面向玩家
	if face_player_on_interact and player:
		_face_toward(player.global_position)

	emit_signal("interacted", player)

	# 开始对话
	_start_dialogue()


## 获取交互提示
func get_interaction_hint() -> String:
	if _has_available_quest:
		return "[E] 与 %s 对话 (有新任务)" % npc_name
	return "[E] 与 %s 对话" % npc_name


## 设置NPC状态
func set_state(new_state: NPCState) -> void:
	_state = new_state


## 获取NPC状态
func get_state() -> NPCState:
	return _state


## 面向指定方向
func face_direction(direction: String) -> void:
	_current_direction = direction
	_update_animation("idle")


## 播放动画
func play_animation(_anim_name: String) -> void:
	# 使用简单的ColorRect，无需动画
	pass


## 显示/隐藏感叹号
func show_exclamation(show: bool) -> void:
	if exclamation:
		exclamation.visible = show
		if show:
			exclamation.text = "!"
		else:
			exclamation.text = ""


## 检查是否有可用任务
func has_available_quest() -> bool:
	return _has_available_quest


# ==================== 私有方法 ====================
func _setup_npc() -> void:
	# 设置碰撞
	collision_layer = 4  # NPC层
	collision_mask = 2   # 与环境碰撞

	# 保存原始位置
	_original_position = global_position

	# 设置名称标签
	if name_label:
		name_label.text = npc_name

	# 初始化动画
	_update_animation("idle")


func _connect_signals() -> void:
	# 信号已在场景中连接，无需重复连接
	pass


func _check_available_quests() -> void:
	_has_available_quest = not available_quests.is_empty()
	show_exclamation(_has_available_quest)


func _handle_idle_behavior(delta: float) -> void:
	if behavior == NPCBehavior.STATIC:
		return

	if _is_waiting:
		_wait_timer -= delta
		if _wait_timer <= 0:
			_is_waiting = false
			_start_movement()
	else:
		match behavior:
			NPCBehavior.PATROL:
				_start_patrol()
			NPCBehavior.RANDOM:
				_start_random_movement()


func _handle_walking_behavior(delta: float) -> void:
	if _facing_player:
		velocity = Vector2.ZERO
		return

	# 检查是否到达目标
	if velocity.length() < 5:
		_state = NPCState.IDLE
		_is_waiting = true
		_wait_timer = randf_range(wait_time_range.x, wait_time_range.y)
		_update_animation("idle")


func _start_movement() -> void:
	_state = NPCState.WALKING
	_update_animation("walk")


func _start_patrol() -> void:
	if patrol_points.is_empty():
		return

	_patrol_index = (_patrol_index + 1) % patrol_points.size()
	var target := patrol_points[_patrol_index]
	_move_toward(target)


func _start_random_movement() -> void:
	var random_offset := Vector2(randf_range(-100, 100), randf_range(-100, 100))
	var target := _original_position + random_offset
	_move_toward(target)


func _move_toward(target: Vector2) -> void:
	var direction := (target - global_position).normalized()
	velocity = direction * move_speed

	# 更新朝向
	if abs(direction.x) > abs(direction.y):
		_current_direction = "right" if direction.x > 0 else "left"
	else:
		_current_direction = "down" if direction.y > 0 else "up"

	_start_movement()


func _face_toward(target_position: Vector2) -> void:
	var direction := target_position - global_position

	if abs(direction.x) > abs(direction.y):
		_current_direction = "right" if direction.x > 0 else "left"
	else:
		_current_direction = "down" if direction.y > 0 else "up"

	_update_animation("idle")


func _update_animation(_base_anim: String) -> void:
	# 使用简单的ColorRect，无需动画
	pass


func _start_dialogue() -> void:
	if dialogue_ids.is_empty():
		_end_dialogue()
		return

	emit_signal("dialogue_started", self)

	# 获取当前对话ID
	var dialogue_id := dialogue_ids[0]

	# 如果有可用任务，触发任务对话
	if _has_available_quest and not available_quests.is_empty():
		emit_signal("quest_offered", self, available_quests[0])

	# TODO: 调用对话系统显示对话
	# DialogueManager.start_dialogue(dialogue_id)


func _end_dialogue() -> void:
	_state = NPCState.IDLE
	_facing_player = false
	emit_signal("dialogue_ended", self)
	_check_available_quests()


# ==================== 信号处理 ====================
func _on_player_entered(body: Node2D) -> void:
	if body is Player:
		# 玩家进入交互范围
		pass


func _on_player_exited(body: Node2D) -> void:
	if body is Player:
		_facing_player = false
		if _state == NPCState.TALKING:
			_end_dialogue()
