extends CanvasLayer
class_name GameUI

# 单例
static var instance: GameUI

# UI节点
var interact_prompt: Label
var dialogue_box: PanelContainer
var dialogue_name: Label
var dialogue_text: Label
var dialogue_indicator: Label

# 对话状态
var is_in_dialogue: bool = false
var current_npc = null  # NPC类型，使用弱类型避免循环依赖
var nearby_npc = null   # 当前附近的NPC
var nearby_door = null  # 当前附近的门
var nearby_hide_spot = null  # 当前附近的躲藏点

signal dialogue_advanced

func _ready():
	instance = self
	layer = 10  # UI层

	# 创建交互提示
	_create_interact_prompt()

	# 创建对话框
	_create_dialogue_box()

func _create_interact_prompt():
	interact_prompt = Label.new()
	interact_prompt.name = "InteractPrompt"
	interact_prompt.position = Vector2(280, 300)
	interact_prompt.add_theme_font_size_override("font_size", 12)
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.visible = false
	add_child(interact_prompt)

func _create_dialogue_box():
	# 对话框容器
	dialogue_box = PanelContainer.new()
	dialogue_box.name = "DialogueBox"
	dialogue_box.position = Vector2(40, 280)
	dialogue_box.custom_minimum_size = Vector2(560, 60)
	dialogue_box.visible = false

	# 背景
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	dialogue_box.add_theme_stylebox_override("panel", style)

	# 内容容器
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	dialogue_box.add_child(vbox)

	# NPC名称
	dialogue_name = Label.new()
	dialogue_name.add_theme_font_size_override("font_size", 11)
	dialogue_name.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	vbox.add_child(dialogue_name)

	# 对话文本
	dialogue_text = Label.new()
	dialogue_text.add_theme_font_size_override("font_size", 12)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogue_text.custom_minimum_size = Vector2(540, 30)
	vbox.add_child(dialogue_text)

	# 继续提示
	dialogue_indicator = Label.new()
	dialogue_indicator.text = "[按E继续]"
	dialogue_indicator.add_theme_font_size_override("font_size", 10)
	dialogue_indicator.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	dialogue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(dialogue_indicator)

	add_child(dialogue_box)

func _input(event: InputEvent):
	if event.is_action_pressed("interact"):
		var player := get_tree().get_first_node_in_group("player") as Player
		if player == null:
			return

		# 优先级：对话 > 躲藏 > 门 > NPC
		if is_in_dialogue and current_npc:
			current_npc.advance_dialogue()
			dialogue_advanced.emit()
		elif player.is_hiding():
			# 玩家在躲藏中，E退出躲藏
			player.exit_hide_spot()
		elif nearby_hide_spot and not is_in_dialogue:
			# 玩家靠近躲藏点，E进入躲藏
			player.enter_hide_spot(nearby_hide_spot)
		elif nearby_door and not is_in_dialogue:
			nearby_door.interact(player)
		elif nearby_npc and not is_in_dialogue:
			nearby_npc.interact()

# 显示交互提示
static func show_interact_prompt(text: String):
	if instance and instance.interact_prompt:
		instance.interact_prompt.text = text
		instance.interact_prompt.visible = true

# 隐藏交互提示
static func hide_interact_prompt():
	if instance and instance.interact_prompt:
		instance.interact_prompt.visible = false

# 显示对话
static func show_dialogue(npc_name: String, text: String):
	if not instance:
		return

	instance.is_in_dialogue = true
	instance.dialogue_box.visible = true
	instance.dialogue_name.text = npc_name
	instance.dialogue_text.text = text

# 隐藏对话
static func hide_dialogue():
	if not instance:
		return

	instance.is_in_dialogue = false
	instance.dialogue_box.visible = false
	instance.current_npc = null

# 设置当前对话中的NPC
static func set_dialogue_npc(npc):
	if instance:
		instance.current_npc = npc

# 设置当前附近的NPC
static func set_nearby_npc(npc, is_nearby: bool):
	if instance:
		if is_nearby:
			instance.nearby_npc = npc
		elif instance.nearby_npc == npc:
			instance.nearby_npc = null

# 设置当前附近的门
static func set_nearby_door(door, is_nearby: bool):
	if instance:
		if is_nearby:
			instance.nearby_door = door
		elif instance.nearby_door == door:
			instance.nearby_door = null

# 设置当前附近的躲藏点
static func set_nearby_hide_spot(spot, is_nearby: bool):
	if instance:
		if is_nearby:
			instance.nearby_hide_spot = spot
		elif instance.nearby_hide_spot == spot:
			instance.nearby_hide_spot = null

# 检查是否在对话中
static func is_dialogue_active() -> bool:
	return instance and instance.is_in_dialogue
