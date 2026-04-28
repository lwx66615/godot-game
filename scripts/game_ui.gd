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

# 物品栏UI
var inventory_panel: PanelContainer
var inventory_title: Label
var item_slots: Array[Button] = []
var item_description: Label
var key_item_slots: Array[Button] = []
var selected_slot: int = -1
var is_inventory_open: bool = false

# 对话状态
var is_in_dialogue: bool = false
var current_npc = null
var nearby_npc = null
var nearby_door = null
var nearby_hide_spot = null
var nearby_item = null
var nearby_searchable = null

signal dialogue_advanced

func _ready():
	instance = self
	layer = 10

	_create_interact_prompt()
	_create_dialogue_box()
	_create_inventory_ui()

func _create_interact_prompt():
	interact_prompt = Label.new()
	interact_prompt.name = "InteractPrompt"
	interact_prompt.position = Vector2(280, 300)
	interact_prompt.add_theme_font_size_override("font_size", 12)
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.visible = false
	add_child(interact_prompt)

func _create_dialogue_box():
	dialogue_box = PanelContainer.new()
	dialogue_box.name = "DialogueBox"
	dialogue_box.position = Vector2(40, 280)
	dialogue_box.custom_minimum_size = Vector2(560, 60)
	dialogue_box.visible = false

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	dialogue_box.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	dialogue_box.add_child(vbox)

	dialogue_name = Label.new()
	dialogue_name.add_theme_font_size_override("font_size", 11)
	dialogue_name.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	vbox.add_child(dialogue_name)

	dialogue_text = Label.new()
	dialogue_text.add_theme_font_size_override("font_size", 12)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogue_text.custom_minimum_size = Vector2(540, 30)
	vbox.add_child(dialogue_text)

	dialogue_indicator = Label.new()
	dialogue_indicator.text = "[按E继续]"
	dialogue_indicator.add_theme_font_size_override("font_size", 10)
	dialogue_indicator.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	dialogue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(dialogue_indicator)

	add_child(dialogue_box)

func _create_inventory_ui():
	# 物品栏面板
	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.position = Vector2(20, 20)
	inventory_panel.custom_minimum_size = Vector2(280, 320)
	inventory_panel.visible = false

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(2)
	inventory_panel.add_theme_stylebox_override("panel", style)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(main_vbox)

	# 标题
	inventory_title = Label.new()
	inventory_title.text = "物品栏 [Tab关闭]"
	inventory_title.add_theme_font_size_override("font_size", 14)
	inventory_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	main_vbox.add_child(inventory_title)

	# 物品格子区域 (4x3网格)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	main_vbox.add_child(grid)

	# 创建12个物品格子
	for i in range(12):
		var slot: Button = Button.new()
		slot.custom_minimum_size = Vector2(60, 50)
		slot.add_theme_font_size_override("font_size", 10)
		slot.toggle_mode = true
		var slot_index: int = i
		slot.pressed.connect(_on_item_slot_pressed.bind(slot_index))
		grid.add_child(slot)
		item_slots.append(slot)

	# 分隔线
	var separator: HSeparator = HSeparator.new()
	separator.custom_minimum_size.y = 2
	main_vbox.add_child(separator)

	# 物品描述
	item_description = Label.new()
	item_description.text = "选择物品查看详情"
	item_description.add_theme_font_size_override("font_size", 11)
	item_description.autowrap_mode = TextServer.AUTOWRAP_WORD
	item_description.custom_minimum_size = Vector2(260, 40)
	main_vbox.add_child(item_description)

	# 关键道具标题
	var key_title: Label = Label.new()
	key_title.text = "关键道具"
	key_title.add_theme_font_size_override("font_size", 12)
	key_title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	main_vbox.add_child(key_title)

	# 关键道具区域 (5格横排)
	var key_hbox: HBoxContainer = HBoxContainer.new()
	key_hbox.add_theme_constant_override("separation", 4)
	main_vbox.add_child(key_hbox)

	for i in range(5):
		var slot: Button = Button.new()
		slot.custom_minimum_size = Vector2(50, 40)
		slot.add_theme_font_size_override("font_size", 9)
		key_hbox.add_child(slot)
		key_item_slots.append(slot)

	add_child(inventory_panel)

func _on_item_slot_pressed(slot_index: int):
	if not Inventory.instance:
		return

	# 取消之前的选择
	if selected_slot >= 0 and selected_slot < item_slots.size():
		item_slots[selected_slot].button_pressed = false

	# 选择新格子
	selected_slot = slot_index
	item_slots[slot_index].button_pressed = true

	# 显示物品信息
	var slot_data: Dictionary = Inventory.instance.items[slot_index]
	if slot_data["id"] != "":
		var item_name: String = Inventory.instance.get_item_name(slot_data["id"])
		var item_desc: String = Inventory.instance.get_item_description(slot_data["id"])
		item_description.text = "%s x%d\n%s" % [item_name, slot_data["count"], item_desc]
	else:
		item_description.text = "空格子"

func _input(event: InputEvent):
	# Tab键打开/关闭物品栏
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_TAB and event.pressed):
		toggle_inventory()
		return

	# 物品栏打开时的输入处理
	if is_inventory_open:
		if event.is_action_pressed("ui_accept"):
			# Enter键使用物品
			if selected_slot >= 0 and Inventory.instance:
				Inventory.instance.use_item(selected_slot)
				_update_inventory_display()
			return
		elif event.is_action_pressed("ui_left"):
			_navigate_slot(-1)
			return
		elif event.is_action_pressed("ui_right"):
			_navigate_slot(1)
			return
		elif event.is_action_pressed("ui_up"):
			_navigate_slot(-4)
			return
		elif event.is_action_pressed("ui_down"):
			_navigate_slot(4)
			return

	# 正常交互
	if event.is_action_pressed("interact"):
		var tree: SceneTree = get_tree()
		if tree == null:
			return
		var player: Player = tree.get_first_node_in_group("player") as Player
		if player == null:
			return

		if is_in_dialogue and current_npc:
			current_npc.advance_dialogue()
			dialogue_advanced.emit()
		elif player.is_hiding():
			player.exit_hide_spot()
		elif nearby_hide_spot and not is_in_dialogue:
			player.enter_hide_spot(nearby_hide_spot)
		elif nearby_door and not is_in_dialogue:
			nearby_door.interact(player)
		elif nearby_item and not is_in_dialogue:
			nearby_item.pickup()
		elif nearby_searchable and not is_in_dialogue:
			nearby_searchable.search()
		elif nearby_npc and not is_in_dialogue:
			nearby_npc.interact()

func toggle_inventory():
	is_inventory_open = not is_inventory_open
	inventory_panel.visible = is_inventory_open

	if is_inventory_open:
		_update_inventory_display()
		if selected_slot < 0:
			selected_slot = 0
		_on_item_slot_pressed(selected_slot)

func _navigate_slot(direction: int):
	if item_slots.is_empty():
		return

	var new_slot: int = selected_slot + direction
	new_slot = wrapi(new_slot, 0, item_slots.size())
	_on_item_slot_pressed(new_slot)

func _update_inventory_display():
	if not Inventory.instance:
		return

	# 更新物品格子
	for i in range(item_slots.size()):
		var slot_data: Dictionary = Inventory.instance.items[i]
		if slot_data["id"] != "":
			var item_name: String = Inventory.instance.get_item_name(slot_data["id"])
			item_slots[i].text = "%s\nx%d" % [item_name.left(4), slot_data["count"]]
		else:
			item_slots[i].text = ""

	# 更新关键道具
	for i in range(key_item_slots.size()):
		if Inventory.instance.key_items[i] != "":
			var item_name: String = Inventory.instance.get_item_name(Inventory.instance.key_items[i])
			key_item_slots[i].text = item_name.left(3)
		else:
			key_item_slots[i].text = ""

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

# 设置当前附近的物品
static func set_nearby_item(item, is_nearby: bool):
	if instance:
		if is_nearby:
			instance.nearby_item = item
		elif instance.nearby_item == item:
			instance.nearby_item = null

# 设置当前附近的可搜刮物体
static func set_nearby_searchable(searchable, is_nearby: bool):
	if instance:
		if is_nearby:
			instance.nearby_searchable = searchable
		elif instance.nearby_searchable == searchable:
			instance.nearby_searchable = null

# 检查是否在对话中
static func is_dialogue_active() -> bool:
	return instance != null and instance.is_in_dialogue
