extends Node2D

# 测试场景 - 技术验证

var player: Player
var ghost: Ghost
var game_manager: GameManager
var game_ui  # GameUI类型，使用弱类型避免加载顺序问题
var test_npc: NPC
var test_door: Door
var test_hide_spot: HideSpot

# UI元素
var state_label: Label
var perception_label: Label
var stamina_label: Label
var speed_label: Label
var time_label: Label
var instruction_label: Label
var door_label: Label
var hide_label: Label

# 测试房间
var test_room: Node2D

func _ready():
	# 创建游戏管理器
	game_manager = GameManager.new()
	add_child(game_manager)

	# 创建音频管理器
	var audio_manager := AudioManager.new()
	add_child(audio_manager)

	# 创建UI
	game_ui = GameUI.new()
	add_child(game_ui)

	# 连接时间信号
	game_manager.period_changed.connect(_on_period_changed)
	game_manager.day_changed.connect(_on_day_changed)
	game_manager.time_changed.connect(_on_time_changed)

	# 创建测试房间
	_create_test_room()

	# 创建玩家（左侧）
	player = Player.new()
	player.position = Vector2(100, 180)

	# 添加玩家视觉（蓝色方块）
	var player_sprite := ColorRect.new()
	player_sprite.color = Color(0.2, 0.6, 0.8)
	player_sprite.size = Vector2(12, 12)
	player_sprite.position = Vector2(-6, -6)  # 居中
	player.add_child(player_sprite)

	add_child(player)

	# 创建诡异（右侧，在屏幕内）
	ghost = Ghost.new()
	ghost.position = Vector2(500, 180)
	ghost.set_target(player)

	# 添加诡异视觉（红色方块）
	var ghost_sprite := ColorRect.new()
	ghost_sprite.color = Color(0.8, 0.2, 0.2)
	ghost_sprite.size = Vector2(16, 16)
	ghost_sprite.position = Vector2(-8, -8)  # 居中
	ghost.add_child(ghost_sprite)

	add_child(ghost)

	# 创建测试NPC（中间位置）
	test_npc = NPC.new()
	test_npc.npc_name = "幸存者A"
	test_npc.npc_id = "A"
	test_npc.position = Vector2(300, 180)
	test_npc.add_dialogue("你好，你终于醒了...")
	test_npc.add_dialogue("这里是大昌一中，我们都是诡异降临的幸存者。")
	test_npc.add_dialogue("记住，夜晚千万不要外出。")
	test_npc.add_dialogue("诡异会在夜晚活动，听到敲门声千万别开门。")

	# 添加NPC视觉（绿色方块）
	var npc_sprite := ColorRect.new()
	npc_sprite.color = Color(0.2, 0.7, 0.3)
	npc_sprite.size = Vector2(12, 12)
	npc_sprite.position = Vector2(-6, -6)
	test_npc.add_child(npc_sprite)

	add_child(test_npc)

	# 创建门（中间位置）
	test_door = Door.new()
	test_door.door_id = "test_door"
	test_door.position = Vector2(400, 180)

	# 添加门视觉
	var door_sprite := ColorRect.new()
	door_sprite.color = Color(0.5, 0.3, 0.2)
	door_sprite.size = Vector2(32, 8)
	door_sprite.position = Vector2(-16, -4)
	test_door.add_child(door_sprite)

	# 设置视觉节点
	test_door.visual_node = door_sprite

	add_child(test_door)

	# 连接门信号
	test_door.door_opened.connect(_on_door_opened)
	test_door.door_closed.connect(_on_door_closed)
	test_door.door_broken.connect(_on_door_broken)
	test_door.player_died_at_door.connect(_on_player_died_at_door)

	# 创建躲藏点（左侧）
	test_hide_spot = HideSpot.new()
	test_hide_spot.hide_type = HideSpot.HideType.CABINET
	test_hide_spot.position = Vector2(80, 300)

	# 添加躲藏点视觉
	var hide_sprite := ColorRect.new()
	hide_sprite.color = Color(0.2, 0.4, 0.2)
	hide_sprite.size = Vector2(24, 32)
	hide_sprite.position = Vector2(-12, -16)
	test_hide_spot.add_child(hide_sprite)

	add_child(test_hide_spot)

	# 连接躲藏点信号
	test_hide_spot.player_entered_hide.connect(_on_player_entered_hide)
	test_hide_spot.player_exited_hide.connect(_on_player_exited_hide)
	test_hide_spot.player_detected.connect(_on_player_detected)

	# 连接信号
	ghost.state_changed.connect(_on_ghost_state_changed)
	ghost.perception_updated.connect(_on_perception_updated)
	ghost.knock_started.connect(_on_knock_started)
	ghost.knock_stage_changed.connect(_on_knock_stage_changed)
	ghost.door_breached.connect(_on_door_breached)
	player.stamina_changed.connect(_on_stamina_changed)
	player.player_moved.connect(_on_player_moved)
	player.player_stopped.connect(_on_player_stopped)
	player.state_changed.connect(_on_player_state_changed)
	player.player_detected_by_ghost.connect(_on_player_detected_by_ghost)
	test_npc.dialogue_started.connect(_on_npc_dialogue_started)
	test_npc.dialogue_ended.connect(_on_npc_dialogue_ended)

	# 创建UI
	_create_ui()

func _create_test_room():
	# 创建简单的测试房间（用矩形表示）
	var room := ColorRect.new()
	room.color = Color(0.1, 0.1, 0.15)
	room.size = Vector2(640, 360)
	room.position = Vector2(0, 0)
	add_child(room)

	# 创建墙壁
	var wall_top := ColorRect.new()
	wall_top.color = Color(0.3, 0.3, 0.35)
	wall_top.size = Vector2(640, 8)
	add_child(wall_top)

	var wall_bottom := ColorRect.new()
	wall_bottom.color = Color(0.3, 0.3, 0.35)
	wall_bottom.size = Vector2(640, 8)
	wall_bottom.position = Vector2(0, 352)
	add_child(wall_bottom)

	# 创建门（中间）
	var door := ColorRect.new()
	door.color = Color(0.5, 0.3, 0.2)
	door.size = Vector2(32, 8)
	door.position = Vector2(304, 352)
	add_child(door)

	# 创建躲藏点标记
	var hide_spot := ColorRect.new()
	hide_spot.color = Color(0.2, 0.4, 0.2)
	hide_spot.size = Vector2(24, 24)
	hide_spot.position = Vector2(80, 300)
	add_child(hide_spot)

	var hide_label := Label.new()
	hide_label.text = "躲藏点"
	hide_label.position = Vector2(80, 290)
	hide_label.add_theme_font_size_override("font_size", 10)
	add_child(hide_label)

func _create_ui():
	# 状态显示
	state_label = Label.new()
	state_label.position = Vector2(10, 10)
	state_label.add_theme_font_size_override("font_size", 12)
	add_child(state_label)

	perception_label = Label.new()
	perception_label.position = Vector2(10, 30)
	perception_label.add_theme_font_size_override("font_size", 12)
	add_child(perception_label)

	stamina_label = Label.new()
	stamina_label.position = Vector2(10, 50)
	stamina_label.add_theme_font_size_override("font_size", 12)
	add_child(stamina_label)

	speed_label = Label.new()
	speed_label.position = Vector2(10, 70)
	speed_label.add_theme_font_size_override("font_size", 12)
	add_child(speed_label)

	time_label = Label.new()
	time_label.position = Vector2(10, 90)
	time_label.add_theme_font_size_override("font_size", 12)
	add_child(time_label)

	instruction_label = Label.new()
	instruction_label.text = "WASD移动 | Shift奔跑 | E交互 | T跳过时段"

	door_label = Label.new()
	door_label.position = Vector2(10, 110)
	door_label.add_theme_font_size_override("font_size", 12)
	add_child(door_label)

	hide_label = Label.new()
	hide_label.position = Vector2(10, 130)
	hide_label.add_theme_font_size_override("font_size", 12)
	add_child(hide_label)

	instruction_label.position = Vector2(10, 340)
	instruction_label.add_theme_font_size_override("font_size", 10)
	add_child(instruction_label)

func _process(_delta):
	# 更新UI
	state_label.text = "诡异状态: " + _get_state_name(ghost.current_state)
	perception_label.text = "感知值: %.1f" % ghost.perception_value
	stamina_label.text = "体力: %.1f%%" % player.stamina
	speed_label.text = "速度: %.0f (%s)" % [player.current_speed, "奔跑中" if player.is_running else "行走"]

	# 时间显示
	var time_str := game_manager.get_time_string()
	var period_name := game_manager.get_period_name()
	time_label.text = "第%d天 %s %s" % [game_manager.current_day, time_str, period_name]

	# 门状态显示
	if test_door:
		door_label.text = "门状态: " + test_door.get_state_name()
		if test_door.is_being_knocked:
			door_label.text += " (正在敲门!)"

	# 躲藏状态显示
	if player.is_hiding():
		hide_label.text = "状态: 躲藏中 (" + test_hide_spot.get_type_name() + ")"
	else:
		hide_label.text = "状态: 正常"

	# 测试：按T跳过1小时
	if Input.is_key_pressed(KEY_T):
		game_manager.skip_time(60)

func _get_state_name(state: int) -> String:
	match state:
		0: return "巡逻"
		1: return "观察"
		2: return "追踪"
		3: return "敲门"
		4: return "破门"
		5: return "搜索"
		_: return "未知"

# ==================== 信号回调 ====================

func _on_ghost_state_changed(new_state: int):
	print("诡异状态变化: ", _get_state_name(new_state))

func _on_perception_updated(value: float):
	# 根据感知值改变诡异颜色
	var intensity := value / 100.0
	# 可以在这里更新诡异视觉效果

func _on_knock_started(door: Door):
	print("诡异开始敲门！门: %s" % door.door_id)

func _on_knock_stage_changed(stage: int):
	print("敲门阶段: ", stage, " (", 3 - stage + 1, "秒后破门)")

func _on_door_breached():
	print("门被破门！")

func _on_stamina_changed(value: float):
	if value <= 20.0:
		print("体力极低！无法奔跑")

func _on_player_moved():
	print("玩家移动 - 诡异感知增强")

func _on_player_stopped():
	print("玩家静止 - 诡异感知衰减")

func _on_player_state_changed(new_state: int):
	var state_names := ["正常", "躲藏"]
	print("玩家状态变化: %s" % state_names[new_state])

func _on_player_detected_by_ghost():
	print("玩家被诡异发现！进入追踪状态！")

func _on_period_changed(new_period: int, old_period: int):
	var period_names := ["早晨", "中午", "傍晚", "夜晚"]
	print("时段变化: %s -> %s" % [period_names[old_period], period_names[new_period]])

func _on_time_changed(new_time: int):
	# 时间变化时可以更新UI或其他逻辑
	pass

func _on_day_changed(new_day: int):
	print("新的一天: 第%d天" % new_day)

func _on_npc_dialogue_started(npc: NPC):
	print("开始与 %s 对话" % npc.npc_name)

func _on_npc_dialogue_ended(npc: NPC):
	print("结束与 %s 对话" % npc.npc_name)

func _on_door_opened(door: Door, _player_pos: Vector2):
	print("门打开: %s" % door.door_id)

func _on_door_closed(door: Door, _player_pos: Vector2):
	print("门关闭: %s" % door.door_id)

func _on_door_broken(door: Door):
	print("门被破坏: %s" % door.door_id)

func _on_player_died_at_door(door: Door):
	print("玩家在门前死亡: %s" % door.door_id)
	# TODO: 实现玩家死亡处理

func _on_player_entered_hide(player: Player, spot: HideSpot):
	print("玩家进入躲藏: %s" % spot.get_type_name())

func _on_player_exited_hide(player: Player, spot: HideSpot):
	print("玩家退出躲藏: %s" % spot.get_type_name())

func _on_player_detected(player: Player, spot: HideSpot):
	print("玩家被诡异发现！躲藏点: %s" % spot.get_type_name())
