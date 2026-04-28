extends CharacterBody2D
class_name Ghost

# 状态枚举
enum State { PATROL, OBSERVE, CHASE, KNOCK, BREACH, SEARCH }

# 当前状态
var current_state := State.PATROL

# 速度参数（像素/秒）
const PATROL_SPEED := 32.0      # 2单位/秒
const CHASE_BASE_SPEED := 56.0  # 3.5单位/秒
const SEARCH_SPEED := 24.0      # 1.5单位/秒

# 感知系统
var perception_value := 0.0  # 0-100
const PERCEPTION_NONE := 20.0
const PERCEPTION_VAGUE := 50.0
const PERCEPTION_CONFIRMED := 80.0

# 感知范围（像素）
const SIGHT_RANGE := 128.0      # 8单位
const HEARING_RANGE := 240.0    # 15单位
const DOOR_SOUND_RANGE := 480.0 # 30单位

# 视野角度（度）
const SIGHT_ANGLE := 60.0  # 120度锥形

# 感知值变化速率
const PERCEPTION_SIGHT_GAIN := 10.0      # /秒
const PERCEPTION_WALK_GAIN := 3.0        # /秒
const PERCEPTION_RUN_GAIN := 8.0         # /秒
const PERCEPTION_STILL_DECAY := 5.0      # /秒
const PERCEPTION_HIDE_DECAY := 10.0      # /秒

# 敲门系统
var knock_time := 0.0
const KNOCK_DURATION := 30.0  # 秒
var knock_stage := 1

# 当前敲门的门
var current_door: Door = null

# 搜索系统
var search_time := 0.0
const SEARCH_BASE_TIME := 20.0
const SEARCH_VARIANCE := 5.0
var search_duration := 0.0

# 躲藏点检测
var hide_check_timer := 0.0
const HIDE_CHECK_INTERVAL := 2.0  # 每2秒检测一次
const HIDE_CHECK_RANGE := 64.0    # 检测范围（像素）

# 目标
var target: Node2D = null
var last_known_position := Vector2.ZERO

# 朝向（用于视野检测）
var facing_direction := Vector2.RIGHT

# 巡逻目标
var patrol_target := Vector2.ZERO
var patrol_wait_time := 0.0

# 躲藏点检测概率
const HIDE_DETECT_STILL := 0.35
const HIDE_DETECT_MOVING := 0.55

# 音效相关
var drag_sound_player: AudioStreamPlayer2D = null
var is_playing_drag_sound := false

signal state_changed(new_state: State)
signal perception_updated(value: float)
signal knock_started(door: Door)
signal knock_stage_changed(stage: int)
signal door_breached(door: Door)
signal player_killed

func _ready():
	add_to_group("ghost")
	# 初始化巡逻目标
	patrol_target = global_position
	search_duration = SEARCH_BASE_TIME + randf_range(-SEARCH_VARIANCE, SEARCH_VARIANCE)

func _physics_process(delta):
	# 更新逃脱道具效果计时器
	_update_escape_item_effects(delta)

	# 更新感知系统
	_update_perception(delta)

	# 如果被逃脱道具吸引，跳过正常行为
	if is_attracted:
		_attract_behavior(delta)
	else:
		# 根据状态执行行为
		match current_state:
			State.PATROL:
				_patrol_behavior(delta)
			State.OBSERVE:
				_observe_behavior(delta)
			State.CHASE:
				_chase_behavior(delta)
			State.KNOCK:
				_knock_behavior(delta)
			State.BREACH:
				_breach_behavior(delta)
			State.SEARCH:
				_search_behavior(delta)

	# 检查状态转换
	_check_state_transition()

	# 更新拖刀声音效位置
	_update_drag_sound()

	move_and_slide()

# ==================== 感知系统 ====================

func _update_perception(delta: float):
	if target == null:
		return

	# 如果感知被护身符屏蔽，只允许衰减
	if is_perception_zero:
		perception_value = max(0.0, perception_value - PERCEPTION_STILL_DECAY * delta)
		perception_updated.emit(perception_value)
		return

	var distance := global_position.distance_to(target.global_position)

	# 视野检测
	if _is_in_sight(target):
		perception_value += PERCEPTION_SIGHT_GAIN * delta

	# 声音检测（基于玩家移动状态）
	var player := target as Player
	if player:
		match player.get_movement_state():
			"walking":
				if distance <= HEARING_RANGE:
					perception_value += PERCEPTION_WALK_GAIN * delta
			"running":
				if distance <= HEARING_RANGE:
					perception_value += PERCEPTION_RUN_GAIN * delta
			"still":
				perception_value -= PERCEPTION_STILL_DECAY * delta

	# 距离衰减
	perception_value -= _get_distance_decay(distance) * delta

	# 限制范围
	perception_value = clamp(perception_value, 0.0, 100.0)
	perception_updated.emit(perception_value)

func _is_in_sight(target_node: Node2D) -> bool:
	if target_node == null:
		return false

	var to_target := target_node.global_position - global_position
	var distance := to_target.length()

	if distance > SIGHT_RANGE:
		return false

	# 检查角度（相对于诡异朝向）
	var angle := rad_to_deg(to_target.angle_to(facing_direction))
	if abs(angle) > SIGHT_ANGLE:
		return false

	# 射线检测：检查是否有墙壁遮挡
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		target_node.global_position,
		0xFFFFFFFF,  # 检测所有碰撞层
		[self]  # 排除自己
	)
	var result := space_state.intersect_ray(query)

	# 如果射线碰到物体，检查是否是目标
	if result and result.collider:
		# 如果碰到的不是目标，说明被遮挡
		if result.collider != target_node:
			return false

	return true

func _get_distance_decay(distance: float) -> float:
	# 简化的距离衰减
	if distance < 64.0:  # 同房间
		return 0.0
	elif distance < 128.0:  # 相邻房间
		return 0.5
	elif distance < 240.0:  # 2-3房间距离
		return 1.0
	elif distance < 400.0:  # 4-5房间距离
		return 2.0
	else:
		return 3.0

# 玩家开门/关门时调用
func on_player_door_action(player_pos: Vector2):
	var distance := global_position.distance_to(player_pos)
	if distance <= DOOR_SOUND_RANGE:
		perception_value += 30.0
	elif distance <= DOOR_SOUND_RANGE * 2:
		perception_value += 15.0
	else:
		perception_value += 5.0
	perception_value = min(perception_value, 100.0)

# ==================== 状态行为 ====================

func _patrol_behavior(_delta: float):
	# 巡逻到目标点
	if global_position.distance_to(patrol_target) > 8.0:
		var direction := (patrol_target - global_position).normalized()
		velocity = direction * PATROL_SPEED
		# 更新朝向
		facing_direction = direction
	else:
		velocity = Vector2.ZERO
		patrol_wait_time -= _delta
		if patrol_wait_time <= 0:
			# 选择新的巡逻目标
			_select_new_patrol_target()
			patrol_wait_time = randf_range(3.0, 5.0)

func _select_new_patrol_target():
	# 简化：随机选择附近一点
	var angle := randf() * TAU
	var distance := randf_range(64.0, 192.0)
	patrol_target = global_position + Vector2(cos(angle), sin(angle)) * distance

func _observe_behavior(_delta: float):
	# 停止移动，朝向玩家
	velocity = Vector2.ZERO
	if target:
		look_at(target.global_position)

func _chase_behavior(_delta: float):
	if target == null:
		return

	# 计算追踪速度
	var chase_speed := CHASE_BASE_SPEED
	var player := target as Player
	if player:
		match player.get_movement_state():
			"running":
				chase_speed = 88.0  # 5.5单位/秒
			"walking":
				chase_speed = 64.0  # 4单位/秒
			"still":
				chase_speed = 56.0  # 3.5单位/秒

	# 追踪玩家
	var to_target := target.global_position - global_position
	var direction := to_target.normalized()
	velocity = direction * chase_speed
	# 更新朝向
	facing_direction = direction

	# 更新最后已知位置
	last_known_position = target.global_position

func _knock_behavior(delta: float):
	velocity = Vector2.ZERO

	# 如果门已经不存在或被破坏，停止敲门
	if current_door == null or current_door.current_state == Door.DoorState.BROKEN:
		_change_state(State.SEARCH)
		return

	# 移动到敲门位置
	var knock_pos := current_door.get_knock_position()
	if global_position.distance_to(knock_pos) > 8.0:
		var direction := (knock_pos - global_position).normalized()
		velocity = direction * PATROL_SPEED
		facing_direction = direction
		return

	knock_time += delta

	# 敲门阶段
	var new_stage := 1
	if knock_time > 20.0:
		new_stage = 3
	elif knock_time > 10.0:
		new_stage = 2

	if new_stage != knock_stage:
		knock_stage = new_stage
		knock_stage_changed.emit(knock_stage)
	# 播放敲门声（根据阶段）
		if AudioManager.instance and current_door:
			AudioManager.instance.play_knock_sound(knock_stage, current_door.global_position)

	# 30秒后破门
	if knock_time >= KNOCK_DURATION:
		_change_state(State.BREACH)

func _breach_behavior(_delta: float):
	velocity = Vector2.ZERO

	# 破门
	if current_door:
		# 播放破门声
		if AudioManager.instance:
			AudioManager.instance.play_breach_sound(current_door.global_position)
		current_door.break_door()
		current_door.stop_knocking()
		door_breached.emit(current_door)
		current_door = null

	# 破门后进入搜索状态
	_change_state(State.SEARCH)
	search_time = 0.0

func _search_behavior(delta: float):
	# 缓慢移动搜索
	velocity = Vector2.RIGHT.rotated(randf() * TAU) * SEARCH_SPEED * 0.5
	search_time += delta

	# 检测附近躲藏点
	hide_check_timer += delta
	if hide_check_timer >= HIDE_CHECK_INTERVAL:
		hide_check_timer = 0.0
		_check_nearby_hide_spots()

	# 搜索时间结束，返回巡逻
	if search_time >= search_duration:
		_change_state(State.PATROL)
		perception_value = 0.0

# 检测附近躲藏点
func _check_nearby_hide_spots():
	var hide_spots := get_tree().get_nodes_in_group("hide_spot")
	for spot_node in hide_spots:
		var spot := spot_node as HideSpot
		if spot and spot.has_player():
			var distance := global_position.distance_to(spot.global_position)
			if distance <= HIDE_CHECK_RANGE:
				# 检测躲藏的玩家
				var player := spot.get_hiding_player() as Player
				if player:
					var was_moving := player.was_moving_when_hiding()
					if spot.check_for_player(was_moving):
						# 发现玩家！
						player.detected_by_ghost()
						target = player
						_change_state(State.CHASE)
						return

# ==================== 状态转换 ====================

func _check_state_transition():
	match current_state:
		State.PATROL:
			if perception_value >= PERCEPTION_VAGUE:
				_change_state(State.OBSERVE)

		State.OBSERVE:
			if perception_value >= PERCEPTION_CONFIRMED:
				_change_state(State.CHASE)
			elif perception_value < PERCEPTION_NONE:
				_change_state(State.PATROL)

		State.CHASE:
			if perception_value < PERCEPTION_NONE:
				_change_state(State.PATROL)
			# TODO: 检测玩家进入房间关门

		State.SEARCH:
			if perception_value >= PERCEPTION_CONFIRMED:
				_change_state(State.CHASE)

func _change_state(new_state: State):
	current_state = new_state
	state_changed.emit(new_state)

	# 状态初始化
	match new_state:
		State.KNOCK:
			knock_time = 0.0
			knock_stage = 1
			if current_door:
				knock_started.emit(current_door)
			# 停止拖刀声
			_stop_drag_sound()
		State.SEARCH:
			search_time = 0.0
			search_duration = SEARCH_BASE_TIME + randf_range(-SEARCH_VARIANCE, SEARCH_VARIANCE)
			# 停止拖刀声
			_stop_drag_sound()
		State.OBSERVE:
			# 停止拖刀声（观察时静止）
			_stop_drag_sound()
		State.CHASE:
			# 开始拖刀声（追踪时）
			_start_drag_sound()
		State.PATROL:
			# 开始拖刀声（巡逻时）
			_start_drag_sound()

# ==================== 外部接口 ====================

func set_target(new_target: Node2D):
	target = new_target

# 玩家关门时调用 - 检测是否应该进入敲门状态
func on_player_closed_door(door: Door, player_pos: Vector2):
	# 增加感知值
	on_player_door_action(player_pos)

	# 检查是否应该去敲门
	var distance := global_position.distance_to(door.global_position)

	# 如果在听觉范围内且感知值足够高，进入敲门状态
	if distance <= DOOR_SOUND_RANGE and perception_value >= PERCEPTION_VAGUE:
		current_door = door
		door.start_knocking(self)
		_change_state(State.KNOCK)

# 玩家开门时调用 - 如果正在敲门，玩家死亡
func on_player_opened_door(door: Door):
	if current_state == State.KNOCK and current_door == door:
		player_killed.emit()

# 玩家躲藏时调用
func player_hiding(is_hiding: bool):
	if is_hiding:
		perception_value -= PERCEPTION_HIDE_DECAY * 0.1  # 快速衰减

# 检测躲藏的玩家
func check_hiding_player(hide_quality: float, is_moving: bool) -> bool:
	var detect_chance := HIDE_DETECT_STILL
	if is_moving:
		detect_chance = HIDE_DETECT_MOVING

	# 根据躲藏质量调整
	detect_chance *= hide_quality

	return randf() < detect_chance

# ==================== 音效系统 ====================

# 开始播放拖刀声
func _start_drag_sound():
	if is_playing_drag_sound:
		return

	if AudioManager.instance:
		drag_sound_player = AudioManager.instance.play_2d("drag_knife", global_position)
		is_playing_drag_sound = true

# 停止播放拖刀声
func _stop_drag_sound():
	if not is_playing_drag_sound:
		return

	if drag_sound_player and is_instance_valid(drag_sound_player):
		drag_sound_player.stop()
		drag_sound_player.queue_free()
	drag_sound_player = null
	is_playing_drag_sound = false

# 更新拖刀声音效位置（跟随诡异）
func _update_drag_sound():
	if is_playing_drag_sound and drag_sound_player and is_instance_valid(drag_sound_player):
		drag_sound_player.global_position = global_position

# ==================== 逃脱道具响应 ====================

# 被逃脱道具吸引
var attract_duration := 0.0
var is_attracted := false
var attract_target_position := Vector2.ZERO  # 吸引目标位置

# 感知值归零
var perception_zero_duration := 0.0
var is_perception_zero := false

# 更新逃脱道具效果计时器
func _update_escape_item_effects(delta: float):
	# 处理吸引效果
	if is_attracted:
		attract_duration -= delta
		if attract_duration <= 0.0:
			is_attracted = false
			attract_duration = 0.0

	# 处理感知归零效果
	if is_perception_zero:
		perception_zero_duration -= delta
		if perception_zero_duration <= 0.0:
			is_perception_zero = false
			perception_zero_duration = 0.0

# 吸引状态行为
func _attract_behavior(_delta: float):
	# 移动到吸引目标位置
	var to_target := attract_target_position - global_position
	var distance := to_target.length()

	if distance > 16.0:  # 还没到达目标位置
		var direction := to_target.normalized()
		velocity = direction * CHASE_BASE_SPEED
		facing_direction = direction
	else:
		# 到达目标位置，停止移动
		velocity = Vector2.ZERO

# 被逃脱道具吸引（沾满血迹的门把手）
func attract_to_position(duration: float, target_pos: Vector2):
	is_attracted = true
	attract_duration = duration
	attract_target_position = target_pos

# 感知值归零（断裂的护身符）
func set_perception_zero(duration: float):
	is_perception_zero = true
	perception_zero_duration = duration
	perception_value = 0.0