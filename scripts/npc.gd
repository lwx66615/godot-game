extends Area2D
class_name NPC

# NPC基础信息
@export var npc_name: String = "NPC"
@export var npc_id: String = "A"  # A-F
@export var interact_range: float = 32.0

# 对话内容（简化版：对话ID数组）
@export var dialogues: Array[String] = []

# 当前状态
var is_interactable: bool = true
var current_dialogue_index: int = 0

# 信号
signal dialogue_started(npc: NPC)
signal dialogue_ended(npc: NPC)

func _ready():
	# 设置碰撞检测（检测player层）
	collision_layer = 4  # interactable层
	collision_mask = 1   # 检测player层

	# 创建碰撞区域
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = interact_range
	collision.shape = shape
	add_child(collision)

	# 连接输入信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 添加到NPC组
	add_to_group("npc")

func _on_body_entered(body: Node2D):
	if body is Player and is_interactable:
		# 显示交互提示
		_show_interact_prompt()
		GameUI.set_nearby_npc(self, true)

func _on_body_exited(body: Node2D):
	if body is Player:
		_hide_interact_prompt()
		GameUI.set_nearby_npc(self, false)

func _show_interact_prompt():
	# 通知UI显示交互提示
	GameUI.show_interact_prompt("按E对话")

func _hide_interact_prompt():
	GameUI.hide_interact_prompt()

func interact():
	if not is_interactable or dialogues.is_empty():
		return

	dialogue_started.emit(self)
	_start_dialogue()

func _start_dialogue():
	if current_dialogue_index >= dialogues.size():
		current_dialogue_index = 0

	# 显示对话UI
	var dialogue_text := dialogues[current_dialogue_index]
	GameUI.show_dialogue(npc_name, dialogue_text)
	GameUI.set_dialogue_npc(self)

	# 消耗时间（基础时间 + 每段对话额外时间）
	if GameManager.instance:
		var time_cost := GameManager.TIME_DIALOGUE_BASE + GameManager.TIME_DIALOGUE_PER_LINE
		GameManager.instance.consume_time(time_cost)

func advance_dialogue():
	current_dialogue_index += 1

	if current_dialogue_index >= dialogues.size():
		# 对话结束
		end_dialogue()
	else:
		# 显示下一段对话
		var dialogue_text := dialogues[current_dialogue_index]
		GameUI.show_dialogue(npc_name, dialogue_text)

func end_dialogue():
	current_dialogue_index = 0
	GameUI.hide_dialogue()
	dialogue_ended.emit(self)

# 设置对话内容
func set_dialogues(new_dialogues: Array[String]):
	dialogues = new_dialogues

# 添加对话
func add_dialogue(text: String):
	dialogues.append(text)

# 设置是否可交互
func set_interactable(value: bool):
	is_interactable = value
