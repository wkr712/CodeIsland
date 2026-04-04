## 玩家控制器
## 负责玩家角色的移动、动画和交互
class_name Player
extends CharacterBody2D

# ==================== 信号 ====================
signal moved(direction: Vector2)
signal interacted(interactable: Node)
signal animation_changed(animation_name: String)
signal direction_changed(new_direction: String)

# ==================== 导出变量 ====================
## 移动速度
@export var move_speed: float = 150.0

## 冲刺速度倍率
@export var sprint_multiplier: float = 1.5

## 加速度
@export var acceleration: float = 800.0

## 减速度
@export var deceleration: float = 1000.0

# ==================== 节点引用 ====================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ==================== 变量 ====================
var _current_direction: String = "down"
var _is_moving: bool = false
var _can_move: bool = true
var _current_interactable: Node = null
var _nearby_interactables: Array[Node] = []

# 方向向量映射
const DIRECTION_VECTORS := {
	"up": Vector2.UP,
	"down": Vector2.DOWN,
	"left": Vector2.LEFT,
	"right": Vector2.RIGHT
}


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_player()
	_connect_signals()


func _physics_process(delta: float) -> void:
	if not _can_move:
		return

	_handle_movement(delta)
	_handle_interaction_detection()


# ==================== 公共方法 ====================
## 禁用移动
func disable_movement() -> void:
	_can_move = false
	velocity = Vector2.ZERO
	_update_animation("idle")


## 启用移动
func enable_movement() -> void:
	_can_move = true


## 设置位置（传送）
func teleport_to(position: Vector2) -> void:
	global_position = position
	velocity = Vector2.ZERO


## 面向指定方向
func face_direction(direction: String) -> void:
	if direction in DIRECTION_VECTORS:
		_current_direction = direction
		_update_animation("idle")


## 获取当前方向
func get_facing_direction() -> String:
	return _current_direction


## 获取面向的位置
func get_facing_position() -> Vector2:
	return global_position + DIRECTION_VECTORS[_current_direction] * 32.0


## 播放动画
func play_animation(anim_name: String) -> void:
	if sprite:
		sprite.play(anim_name)
		emit_signal("animation_changed", anim_name)


# ==================== 私有方法 ====================
func _setup_player() -> void:
	# 设置碰撞层
	collision_layer = 1  # 玩家层
	collision_mask = 2 | 4  # 与环境层和NPC层碰撞

	# 初始化状态
	_current_direction = "down"


func _connect_signals() -> void:
	# 信号已在场景中连接，无需重复连接
	pass


func _handle_movement(delta: float) -> void:
	# 获取输入方向
	var input_direction := _get_input_direction()

	if input_direction != Vector2.ZERO:
		# 更新方向
		_update_direction(input_direction)

		# 计算目标速度
		var speed := move_speed
		if Input.is_action_pressed("sprint"):
			speed *= sprint_multiplier

		var target_velocity := input_direction * speed

		# 平滑加速
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		_is_moving = true

		# 更新动画
		_update_animation("walk")

		emit_signal("moved", input_direction)
	else:
		# 平滑减速
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		_is_moving = false

		# 更新动画
		_update_animation("idle")

	# 应用移动
	move_and_slide()


func _get_input_direction() -> Vector2:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1

	return direction.normalized()


func _update_direction(input_direction: Vector2) -> void:
	var new_direction := _current_direction

	# 根据输入方向确定面向方向
	if abs(input_direction.x) > abs(input_direction.y):
		new_direction = "right" if input_direction.x > 0 else "left"
	else:
		new_direction = "down" if input_direction.y > 0 else "up"

	if new_direction != _current_direction:
		_current_direction = new_direction
		emit_signal("direction_changed", _current_direction)


func _update_animation(base_anim: String) -> void:
	if sprite == null:
		return

	var anim_name := "%s_%s" % [base_anim, _current_direction]

	# 检查动画是否存在
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		# 降级到基础动画
		sprite.play(base_anim)

	emit_signal("animation_changed", anim_name)


func _handle_interaction_detection() -> void:
	# 检测交互输入
	if Input.is_action_just_pressed("interact"):
		_try_interact()


func _try_interact() -> void:
	if _current_interactable:
		emit_signal("interacted", _current_interactable)
		return

	# 没有直接接触的交互对象，尝试面对方向的交互
	var facing_pos := get_facing_position()
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = facing_pos
	query.collision_mask = 4  # NPC层

	var results := space_state.intersect_point(query)
	if results.size() > 0:
		var collider = results[0].collider
		emit_signal("interacted", collider)


# ==================== 信号处理 ====================
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.has_method("interact"):
		_nearby_interactables.append(body)
		_current_interactable = body

		# 显示交互提示
		if body.has_method("get_interaction_hint"):
			var hint: String = body.get_interaction_hint()
			# TODO: 显示UI提示


func _on_interaction_area_body_exited(body: Node2D) -> void:
	_nearby_interactables.erase(body)

	if _current_interactable == body:
		_current_interactable = null

		# 选择下一个可交互对象
		if not _nearby_interactables.is_empty():
			_current_interactable = _nearby_interactables[0]
		else:
			# TODO: 隐藏UI提示
			pass
