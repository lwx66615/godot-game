extends CharacterBody2D
class_name Player

# 玩家状态
enum PlayerState { NORMAL, HIDING }

# 当前状态
var current_state := PlayerState.NORMAL

# 移动速度（单位：像素/秒）
const WALK_SPEED := 48.0  # 3单位/秒 (16像素 = 1单位)
const RUN_SPEED := 96.0   # 6单位/秒

# 当前状态
var is_running := false
var is_still := false
var current_speed := WALK_SPEED

# 躲藏相关
var current_hide_spot: HideSpot = null
var was_moving_before_hide := false  # 进入躲藏时是否在移动

# 时间消耗相关
var last_position: Vector2 = Vector2.ZERO
var move_distance_accumulated := 0.0  # 累计移动距离
const DISTANCE_PER_ROOM := 320.0  # 一个房间的距离（像素）

# 音效相关
var footstep_timer := 0.0
const FOOTSTEP_WALK_INTERVAL := 0.4  # 行走脚步间隔
const FOOTSTEP_RUN_INTERVAL := 0.2   # 奔跑脚步间隔

# 资源值
var hunger := 100.0
var thirst := 100.0
var stamina := 100.0
var sanity := 100.0

# 受伤状态
var is_light_wounded := false
var is_heavy_wounded := false

# 体力消耗速率（按设计文档：行走0.5%/秒，奔跑3%/秒）
const STAMINA_WALK_COST := 0.5   # %/秒
const STAMINA_RUN_COST := 3.0    # %/秒

# 体力状态阈值
const STAMINA_NO_RUN_THRESHOLD := 50.0
const STAMINA_SLOW_THRESHOLD := 20.0

signal stamina_changed(value: float)
signal player_moved
signal player_stopped
signal state_changed(new_state: PlayerState)
signal player_detected_by_ghost
signal time_consumed(minutes: int)

func _ready():
	add_to_group("player")

	# 设置碰撞层（layer 1 = player）
	collision_layer = 1
	collision_mask = 1 | 4  # 检测player和interactable

	# 添加碰撞体（用于NPC检测）
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)

	# 记录初始位置
	last_position = global_position

func _physics_process(delta):
	# 躲藏状态下不处理移动
	if current_state == PlayerState.HIDING:
		_handle_hiding_state(delta)
		return

	# 处理输入
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# 检测是否静止
	var was_still := is_still
	is_still = input_dir == Vector2.ZERO

	# 发送静止/移动信号（用于诡异感知）
	if is_still and not was_still:
		player_stopped.emit()
	elif not is_still and was_still:
		player_moved.emit()

	# 处理奔跑：直接检测Shift键（不依赖输入映射）
	var run_pressed := Input.is_key_pressed(KEY_SHIFT)
	is_running = run_pressed and stamina > STAMINA_NO_RUN_THRESHOLD and not is_still

	# 计算速度
	if stamina <= STAMINA_SLOW_THRESHOLD:
		current_speed = WALK_SPEED * 0.4  # 体力极低，速度降低60%
	elif stamina <= STAMINA_NO_RUN_THRESHOLD:
		current_speed = WALK_SPEED * 0.7  # 体力低，速度降低30%
	elif is_running:
		current_speed = RUN_SPEED
	else:
		current_speed = WALK_SPEED

	# 消耗体力（只在移动时消耗）
	if not is_still:
		if is_running:
			stamina -= STAMINA_RUN_COST * delta
		else:
			stamina -= STAMINA_WALK_COST * delta
		stamina = max(stamina, 0.0)
		stamina_changed.emit(stamina)

	# 移动
	velocity = input_dir * current_speed
	move_and_slide()

	# 脚步声
	if not is_still:
		footstep_timer += delta
		var interval := FOOTSTEP_RUN_INTERVAL if is_running else FOOTSTEP_WALK_INTERVAL
		if footstep_timer >= interval:
			footstep_timer = 0.0
			if AudioManager.instance:
				AudioManager.instance.play_footstep(is_running)
	else:
		footstep_timer = 0.0

	# 计算移动距离并消耗时间
	if not is_still:
		var moved_distance := global_position.distance_to(last_position)
		move_distance_accumulated += moved_distance
		last_position = global_position

		# 每移动一个房间的距离，消耗时间
		if move_distance_accumulated >= DISTANCE_PER_ROOM:
			var rooms_moved := int(move_distance_accumulated / DISTANCE_PER_ROOM)
			move_distance_accumulated -= rooms_moved * DISTANCE_PER_ROOM

			# 消耗时间
			if GameManager.instance:
				var time_cost := rooms_moved * GameManager.TIME_MOVE_ROOM
				GameManager.instance.consume_time(time_cost)
				time_consumed.emit(time_cost)
	else:
		last_position = global_position

# 恢复体力
func recover_stamina(amount: float):
	stamina = min(stamina + amount, 100.0)
	stamina_changed.emit(stamina)

# 获取当前移动状态（用于诡异感知）
func get_movement_state() -> String:
	if is_still:
		return "still"
	elif is_running:
		return "running"
	else:
		return "walking"

# 获取当前速度倍率（用于诡异追踪速度计算）
func get_speed_multiplier() -> float:
	if is_running:
		return 1.0
	elif not is_still:
		return 0.5
	else:
		return 0.0

# ==================== 躲藏系统 ====================

func _handle_hiding_state(_delta: float):
	# 躲藏状态下不移动
	velocity = Vector2.ZERO

	# TODO: 理智值下降（预留接口）
	# if current_hide_spot:
	#     sanity -= SANITY_HIDE_COST * delta

# 进入躲藏
func enter_hide_spot(spot: HideSpot) -> bool:
	if current_state == PlayerState.HIDING:
		return false

	# 记录进入时的移动状态（影响检测概率）
	was_moving_before_hide = not is_still

	# 进入躲藏
	current_hide_spot = spot
	current_state = PlayerState.HIDING
	velocity = Vector2.ZERO

	# 通知躲藏点
	if not spot.player_enter(self):
		current_hide_spot = null
		current_state = PlayerState.NORMAL
		return false

	state_changed.emit(current_state)
	return true

# 退出躲藏
func exit_hide_spot() -> bool:
	if current_state != PlayerState.HIDING:
		return false

	if current_hide_spot == null:
		current_state = PlayerState.NORMAL
		return true

	# 通知躲藏点
	current_hide_spot.player_exit(self)
	current_hide_spot = null
	current_state = PlayerState.NORMAL

	state_changed.emit(current_state)
	return true

# 被诡异发现（从躲藏点）
func detected_by_ghost():
	if current_state == PlayerState.HIDING and current_hide_spot:
		# 退出躲藏
		current_hide_spot.player_exit(self)
		current_hide_spot = null
		current_state = PlayerState.NORMAL
		state_changed.emit(current_state)

		# 发出被发现信号
		player_detected_by_ghost.emit()

# 检查是否在躲藏
func is_hiding() -> bool:
	return current_state == PlayerState.HIDING

# 获取进入躲藏时的移动状态
func was_moving_when_hiding() -> bool:
	return was_moving_before_hide

# ==================== 受伤与治疗 ====================

# 治疗轻伤
func heal_light_wound():
	is_light_wounded = false

# 治疗重伤
func heal_heavy_wound():
	is_heavy_wounded = false
	is_light_wounded = false

# 受到轻伤
func take_light_wound():
	is_light_wounded = true

# 受到重伤
func take_heavy_wound():
	is_heavy_wounded = true
	is_light_wounded = true