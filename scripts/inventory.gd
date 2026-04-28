extends Node
class_name Inventory

# 单例
static var instance: Inventory

# ==================== 枚举定义 ====================

enum ItemCategory { CONSUMABLE, ESCAPE_ITEM, KEY_ITEM, TOOL, DOCUMENT }
enum EffectType { RESTORE_HUNGER, RESTORE_THIRST, RESTORE_STAMINA, RESTORE_SANITY, COST_SANITY, HEAL_LIGHT, HEAL_HEAVY, ATTRACT_GHOST, HIDE_FROM_GHOST }

# ==================== 物品数据定义 ====================

var ITEM_DATABASE: Dictionary = {
	# 消耗品 - 食物
	"biscuit": {
		"name": "饼干",
		"description": "一包未开封的饼干，看起来还能吃。",
		"category": 0,
		"max_stack": 5,
		"effects": [{"type": 0, "value": 20.0}],
		"use_time": 2.0
	},
	"bread": {
		"name": "面包",
		"description": "半块面包，有些干了但还能吃。",
		"category": 0,
		"max_stack": 5,
		"effects": [{"type": 0, "value": 20.0}],
		"use_time": 2.0
	},
	"canned_food": {
		"name": "罐头",
		"description": "一罐密封的食品，应该还能吃。",
		"category": 0,
		"max_stack": 3,
		"effects": [{"type": 0, "value": 30.0}],
		"use_time": 2.0
	},
	"energy_bar": {
		"name": "能量棒",
		"description": "高热量能量棒，能快速补充体力。",
		"category": 0,
		"max_stack": 3,
		"effects": [{"type": 0, "value": 40.0}, {"type": 2, "value": 10.0}],
		"use_time": 2.0
	},
	"bottled_water": {
		"name": "瓶装水",
		"description": "一瓶未开封的矿泉水。",
		"category": 0,
		"max_stack": 5,
		"effects": [{"type": 1, "value": 25.0}],
		"use_time": 2.0
	},
	"purified_water": {
		"name": "净化水",
		"description": "经过净化的水，更加干净。",
		"category": 0,
		"max_stack": 3,
		"effects": [{"type": 1, "value": 50.0}],
		"use_time": 2.0
	},
	"bandage": {
		"name": "绷带",
		"description": "简单的医疗绷带，可以处理轻伤。",
		"category": 0,
		"max_stack": 3,
		"effects": [{"type": 5}],
		"use_time": 5.0
	},
	"first_aid": {
		"name": "急救包",
		"description": "完整的急救包，可以处理重伤。",
		"category": 0,
		"max_stack": 1,
		"effects": [{"type": 6}],
		"use_time": 5.0
	},
	"sedative": {
		"name": "镇静剂",
		"description": "可以平复精神状态的药物。",
		"category": 0,
		"max_stack": 2,
		"effects": [{"type": 3, "value": 15.0}],
		"use_time": 5.0
	},
	"bloody_doorknob": {
		"name": "沾满血迹的门把手",
		"description": "这个门把手上有干涸的血迹。握着它，你能感受到某种执念。",
		"category": 1,
		"max_stack": 1,
		"effects": [{"type": 7, "value": 15.0}, {"type": 4, "value": 5.0}],
		"use_time": 1.0
	},
	"broken_amulet": {
		"name": "断裂的护身符",
		"description": "一个断裂的护身符，残留了部分保护力量。",
		"category": 1,
		"max_stack": 1,
		"effects": [{"type": 8, "value": 10.0}, {"type": 4, "value": 3.0}],
		"use_time": 1.0
	},
	"seal_box": {
		"name": "封印铁盒",
		"description": "一个特制的铁盒，用于关押诡异。",
		"category": 2,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"box_key": {
		"name": "铁盒钥匙",
		"description": "用于锁上封印铁盒的钥匙。",
		"category": 2,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"library_key": {
		"name": "图书馆钥匙",
		"description": "教学楼三层图书馆的钥匙。",
		"category": 2,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"flashlight": {
		"name": "手电筒",
		"description": "可以照亮黑暗区域。",
		"category": 3,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"crowbar": {
		"name": "撬棍",
		"description": "可以撬开被锁住的门或柜子。",
		"category": 3,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"empty_bottle": {
		"name": "空水瓶",
		"description": "可以在饮水机装水。",
		"category": 3,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"battery": {
		"name": "电池",
		"description": "可以为手电筒提供续航。",
		"category": 3,
		"max_stack": 3,
		"effects": [],
		"use_time": 0.0
	},
	"diary_a": {
		"name": "幸存者日记A",
		"description": "NPC A的日记，记录了诡异降临初期的情况。",
		"category": 4,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"research_note_c": {
		"name": "研究笔记C",
		"description": "NPC C的研究笔记，分析了诡异的规律。",
		"category": 4,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"full_research_note": {
		"name": "完整研究笔记",
		"description": "完整的研究笔记，包含关押诡异的方法。",
		"category": 4,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"seal_evidence": {
		"name": "成功关押证据",
		"description": "证明诡异可以被关押的证据。",
		"category": 4,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"safe_route_info": {
		"name": "外界安全路线信息",
		"description": "通往外界的相对安全路线信息。",
		"category": 4,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	},
	"ghost_rule_note": {
		"name": "诡异规律描述",
		"description": "完整描述诡异行为规律的笔记。",
		"category": 4,
		"max_stack": 1,
		"effects": [],
		"use_time": 0.0
	}
}

# ==================== 物品栏数据 ====================

const MAX_ITEMS := 12
const MAX_KEY_ITEMS := 5

var items: Array[Dictionary] = []
var key_items: Array[String] = []
var documents: Array[String] = []

# ==================== 信号 ====================

signal inventory_changed
signal item_used(item_id: String)
signal key_item_added(item_id: String)
signal document_added(item_id: String)

# ==================== 初始化 ====================

func _ready():
	instance = self
	for i in range(MAX_ITEMS):
		items.append({"id": "", "count": 0})
	for i in range(MAX_KEY_ITEMS):
		key_items.append("")

# ==================== 核心方法 ====================

func get_item_data(item_id: String) -> Dictionary:
	return ITEM_DATABASE.get(item_id, {})

func get_item_name(item_id: String) -> String:
	var data: Dictionary = get_item_data(item_id)
	return data.get("name", "未知物品")

func get_item_description(item_id: String) -> String:
	var data: Dictionary = get_item_data(item_id)
	return data.get("description", "")

func add_item(item_id: String, count: int = 1) -> bool:
	var item_data: Dictionary = get_item_data(item_id)
	if item_data.is_empty():
		push_warning("物品不存在: %s" % item_id)
		return false

	var category: int = item_data.get("category", 0)

	if category == 2:  # KEY_ITEM
		return _add_key_item(item_id)

	if category == 4:  # DOCUMENT
		return _add_document(item_id)

	var max_stack: int = item_data.get("max_stack", 1)
	var remaining: int = count

	if max_stack > 1:
		for i in range(items.size()):
			if items[i]["id"] == item_id:
				var space: int = max_stack - items[i]["count"]
				if space > 0:
					var add: int = mini(remaining, space)
					items[i]["count"] += add
					remaining -= add
					if remaining <= 0:
						inventory_changed.emit()
						return true

	while remaining > 0:
		var empty_index: int = _find_empty_slot()
		if empty_index == -1:
			push_warning("物品栏已满")
			inventory_changed.emit()
			return count > remaining

		var add: int = mini(remaining, max_stack)
		items[empty_index] = {"id": item_id, "count": add}
		remaining -= add

	inventory_changed.emit()
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	var remaining: int = count

	for i in range(items.size()):
		if items[i]["id"] == item_id and items[i]["count"] > 0:
			if items[i]["count"] >= remaining:
				items[i]["count"] -= remaining
				if items[i]["count"] <= 0:
					items[i] = {"id": "", "count": 0}
				inventory_changed.emit()
				return true
			else:
				remaining -= items[i]["count"]
				items[i] = {"id": "", "count": 0}

	inventory_changed.emit()
	return remaining <= 0

func use_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= items.size():
		return false

	var slot: Dictionary = items[slot_index]
	if slot["id"] == "" or slot["count"] <= 0:
		return false

	if not _can_use_item():
		return false

	var item_id: String = slot["id"]
	var item_data: Dictionary = get_item_data(item_id)

	_apply_effects(item_id)

	var use_time: float = item_data.get("use_time", 0.0)
	if use_time > 0.0 and GameManager.instance:
		var time_minutes: int = int(use_time * 0.5)
		if time_minutes > 0:
			GameManager.instance.consume_time(time_minutes)

	var category: int = item_data.get("category", 0)
	if category == 0 or category == 1:  # CONSUMABLE or ESCAPE_ITEM
		slot["count"] -= 1
		if slot["count"] <= 0:
			items[slot_index] = {"id": "", "count": 0}

	item_used.emit(item_id)
	inventory_changed.emit()
	return true

func get_item_count(item_id: String) -> int:
	var total: int = 0
	for slot in items:
		if slot["id"] == item_id:
			total += slot["count"]
	return total

func has_key_item(item_id: String) -> bool:
	return key_items.has(item_id)

func has_document(item_id: String) -> bool:
	return documents.has(item_id)

# ==================== 内部方法 ====================

func _find_empty_slot() -> int:
	for i in range(items.size()):
		if items[i]["id"] == "" or items[i]["count"] <= 0:
			return i
	return -1

func _add_key_item(item_id: String) -> bool:
	if key_items.has(item_id):
		return true

	for i in range(key_items.size()):
		if key_items[i] == "":
			key_items[i] = item_id
			key_item_added.emit(item_id)
			inventory_changed.emit()
			return true

	push_warning("关键道具栏已满")
	return false

func _add_document(item_id: String) -> bool:
	if documents.has(item_id):
		return true

	documents.append(item_id)
	document_added.emit(item_id)
	inventory_changed.emit()
	return true

func _can_use_item() -> bool:
	var player: Player = _get_player()

	if player and player.is_running:
		return false

	if player and player.is_hiding():
		return false

	return true

func _apply_effects(item_id: String) -> void:
	var item_data: Dictionary = get_item_data(item_id)
	var effects: Array = item_data.get("effects", [])

	var player: Player = _get_player()
	var ghost: Ghost = _get_ghost()

	for effect in effects:
		var type: int = effect.get("type", -1)
		var value: float = effect.get("value", 0.0)

		match type:
			0:  # RESTORE_HUNGER
				if player:
					player.hunger = mini(100.0, player.hunger + value)
			1:  # RESTORE_THIRST
				if player:
					player.thirst = mini(100.0, player.thirst + value)
			2:  # RESTORE_STAMINA
				if player:
					player.stamina = mini(100.0, player.stamina + value)
			3:  # RESTORE_SANITY
				if player:
					player.sanity = mini(100.0, player.sanity + value)
			4:  # COST_SANITY
				if player:
					player.sanity = maxf(0.0, player.sanity - value)
			5:  # HEAL_LIGHT
				if player:
					player.heal_light_wound()
			6:  # HEAL_HEAVY
				if player:
					player.heal_heavy_wound()
			7:  # ATTRACT_GHOST
				if ghost and player:
					ghost.attract_to_position(value, player.global_position)
			8:  # HIDE_FROM_GHOST
				if ghost:
					ghost.set_perception_zero(value)

func _get_player() -> Player:
	var tree: SceneTree = get_tree()
	if not tree:
		return null
	return tree.get_first_node_in_group("player") as Player

func _get_ghost() -> Ghost:
	var tree: SceneTree = get_tree()
	if not tree:
		return null
	return tree.get_first_node_in_group("ghost") as Ghost

# ==================== 调试方法 ====================

func debug_print_inventory():
	print("=== 物品栏 ===")
	for i in range(items.size()):
		if items[i]["id"] != "":
			print("  [%d] %s x%d" % [i, get_item_name(items[i]["id"]), items[i]["count"]])
		else:
			print("  [%d] (空)" % i)

	print("=== 关键道具 ===")
	for i in range(key_items.size()):
		if key_items[i] != "":
			print("  [%d] %s" % [i, get_item_name(key_items[i])])
		else:
			print("  [%d] (空)" % i)

	print("=== 文档 ===")
	for doc_id in documents:
		print("  - %s" % get_item_name(doc_id))
