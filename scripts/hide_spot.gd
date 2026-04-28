extends Area2D
class_name HideSpot

# 躲藏点类型
enum HideType { CABINET, DESK, SHADOW }

# 当前类型
@export var hide_type: HideType = HideType.CABINET

# 检测概率基数（根据类型自动设置）
var hide_quality: float = 1.0

# 当前躲藏的玩家
var hiding_player: Player = null

# 信号
signal player_entered_hide(player: Player, spot: HideSpot)
signal player_exited_hide(player: Player, spot: HideSpot)
signal player_detected(player: Player, spot: HideSpot)

func _ready():
	add_to_group("hide_spot")

	# 设置碰撞层
	collision_layer = 4  # interactable层
	collision_mask = 1   # 检测player层

	# 根据类型设置检测概率基数
	_set_hide_quality()

	# 创建碰撞区域
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	match hide_type:
		HideType.CABINET:
			shape.size = Vector2(24, 32)
		HideType.DESK:
			shape.size = Vector2(32, 16)
		HideType.SHADOW:
			shape.size = Vector2(48, 48)
	collision.shape = shape
	add_child(collision)

	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _set_hide_quality():
	# 根据设计文档设置检测概率基数
	# 数值越低，越难被发现
	match hide_type:
		HideType.CABINET:
			hide_quality = 0.3  # 静止30%，移动50%
		HideType.DESK:
			hide_quality = 0.4  # 静止40%，移动60%
		HideType.SHADOW:
			hide_quality = 0.5  # 静止50%，移动80%

func _on_body_entered(body: Node2D):
	if body is Player and hiding_player == null:
		GameUI.show_interact_prompt("按E躲藏")
		GameUI.set_nearby_hide_spot(self, true)

func _on_body_exited(body: Node2D):
	if body is Player:
		GameUI.hide_interact_prompt()
		GameUI.set_nearby_hide_spot(self, false)

# 玩家进入躲藏
func player_enter(player: Player) -> bool:
	if hiding_player != null:
		return false  # 已有人躲藏

	hiding_player = player
	player_entered_hide.emit(player, self)

	# 消耗时间
	if GameManager.instance:
		GameManager.instance.consume_time(GameManager.TIME_HIDE)

	return true

# 玩家退出躲藏
func player_exit(player: Player) -> bool:
	if hiding_player != player:
		return false  # 不是这个玩家

	hiding_player = null
	player_exited_hide.emit(player, self)
	return true

# 诡异检测躲藏的玩家
func check_for_player(is_player_moving: bool) -> bool:
	if hiding_player == null:
		return false

	# 计算检测概率
	var detect_chance := hide_quality
	if is_player_moving:
		# 移动时检测概率更高
		match hide_type:
			HideType.CABINET:
				detect_chance = 0.5
			HideType.DESK:
				detect_chance = 0.6
			HideType.SHADOW:
				detect_chance = 0.8

	# 随机判定
	var detected := randf() < detect_chance
	if detected:
		player_detected.emit(hiding_player, self)

	return detected

# 获取类型名称
func get_type_name() -> String:
	match hide_type:
		HideType.CABINET:
			return "柜子"
		HideType.DESK:
			return "桌子下"
		HideType.SHADOW:
			return "阴影角落"
		_:
			return "躲藏点"

# 是否有玩家躲藏
func has_player() -> bool:
	return hiding_player != null

# 获取躲藏的玩家
func get_hiding_player() -> Player:
	return hiding_player
