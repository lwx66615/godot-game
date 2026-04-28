extends Area2D
class_name Door

# 门状态
enum DoorState { OPEN, CLOSED, BROKEN }

# 当前状态
var current_state := DoorState.CLOSED

# 门的位置（用于诡异导航）
@export var door_id: String = ""

# 敲门位置（诡异站在这里敲门）
var knock_position: Vector2

# 信号
signal door_opened(door: Door, player_pos: Vector2)
signal door_closed(door: Door, player_pos: Vector2)
signal door_broken(door: Door)
signal player_died_at_door(door: Door)

# 诡异敲门相关
var is_being_knocked: bool = false
var knock_ghost = null  # 正在敲门的诡异

# 视觉节点（可选，由子类或场景设置）
var visual_node: Node = null

func _ready():
	# 设置碰撞层
	collision_layer = 4  # interactable层
	collision_mask = 1   # 检测player层

	# 创建碰撞区域
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 8)  # 门的大小
	collision.shape = shape
	add_child(collision)

	# 计算敲门位置（门前）
	knock_position = global_position + Vector2(0, -24)  # 门前24像素

	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body is Player and current_state != DoorState.BROKEN:
		GameUI.show_interact_prompt(_get_interact_text())
		GameUI.set_nearby_door(self, true)

func _on_body_exited(body: Node2D):
	if body is Player:
		GameUI.hide_interact_prompt()
		GameUI.set_nearby_door(self, false)

func _get_interact_text() -> String:
	match current_state:
		DoorState.OPEN:
			return "按E关门"
		DoorState.CLOSED:
			return "按E开门"
		DoorState.BROKEN:
			return "门已损坏"
		_:
			return ""

# 玩家交互
func interact(player: Node2D) -> bool:
	if current_state == DoorState.BROKEN:
		return false

	# 检查是否在敲门期间开门
	if current_state == DoorState.CLOSED and is_being_knocked:
		# 玩家开门即死
		player_died_at_door.emit(self)
		return false

	# 切换状态
	match current_state:
		DoorState.OPEN:
			_close_door(player.global_position)
		DoorState.CLOSED:
			_open_door(player.global_position)

	return true

func _open_door(player_pos: Vector2):
	current_state = DoorState.OPEN
	door_opened.emit(self, player_pos)

	# 播放开门声
	if AudioManager.instance:
		AudioManager.instance.play_door_sound(true)

	# 通知所有诡异
	_notify_ghosts_door_opened(player_pos)
	_update_visual()

func _close_door(player_pos: Vector2):
	current_state = DoorState.CLOSED
	door_closed.emit(self, player_pos)

	# 播放关门声
	if AudioManager.instance:
		AudioManager.instance.play_door_sound(false)

	# 通知所有诡异
	_notify_ghosts_door_closed(player_pos)
	_update_visual()

# 通知诡异门被打开
func _notify_ghosts_door_opened(_player_pos: Vector2):
	var ghosts := get_tree().get_nodes_in_group("ghost")
	for ghost_node in ghosts:
		var ghost := ghost_node as Ghost
		if ghost:
			ghost.on_player_opened_door(self)

# 通知诡异门被关闭
func _notify_ghosts_door_closed(player_pos: Vector2):
	var ghosts := get_tree().get_nodes_in_group("ghost")
	for ghost_node in ghosts:
		var ghost := ghost_node as Ghost
		if ghost:
			ghost.on_player_closed_door(self, player_pos)

# 诡异破门
func break_door():
	if current_state == DoorState.BROKEN:
		return

	current_state = DoorState.BROKEN
	is_being_knocked = false
	knock_ghost = null
	door_broken.emit(self)
	_update_visual()

# 开始被敲门
func start_knocking(ghost):
	is_being_knocked = true
	knock_ghost = ghost

# 停止敲门
func stop_knocking():
	is_being_knocked = false
	knock_ghost = null

# 获取敲门位置
func get_knock_position() -> Vector2:
	return knock_position

# 检查是否可以通过
func can_pass_through() -> bool:
	return current_state == DoorState.OPEN or current_state == DoorState.BROKEN

# 更新视觉表现
func _update_visual():
	# 如果有视觉节点，更新其颜色
	if visual_node and visual_node is CanvasItem:
		match current_state:
			DoorState.OPEN:
				visual_node.modulate = Color(0.3, 0.2, 0.15, 0.5)  # 半透明（打开）
			DoorState.CLOSED:
				visual_node.modulate = Color(0.5, 0.3, 0.2)  # 正常颜色
			DoorState.BROKEN:
				visual_node.modulate = Color(0.3, 0.15, 0.1)  # 深色（损坏）

# 获取状态名称
func get_state_name() -> String:
	match current_state:
		DoorState.OPEN:
			return "打开"
		DoorState.CLOSED:
			return "关闭"
		DoorState.BROKEN:
			return "损坏"
		_:
			return "未知"
