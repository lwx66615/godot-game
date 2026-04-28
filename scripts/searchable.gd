extends Area2D
class_name Searchable

## 可搜刮物体类
## 玩家靠近后可按E搜刮，消耗时间和体力，获得物品

@export var search_name: String = "储物柜"
@export var loot_table: Array[Dictionary] = []
@export var search_time: int = 15  # 分钟（游戏内时间）
@export var stamina_cost: float = 5.0  # 百分比

var is_searched: bool = false

signal searched(searchable: Searchable, items: Array)

func _ready():
	add_to_group("searchable")
	collision_layer = 4  # interactable层
	collision_mask = 1   # 检测player层

	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape
	add_child(collision)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body is Player and not is_searched:
		GameUI.show_interact_prompt("按E搜刮 " + search_name)
		GameUI.set_nearby_searchable(self, true)

func _on_body_exited(body: Node2D):
	if body is Player:
		GameUI.hide_interact_prompt()
		GameUI.set_nearby_searchable(self, false)

## 执行搜刮
func search() -> bool:
	if is_searched:
		return false

	# 检查体力
	var player: Player = _get_player()
	if player and player.stamina < stamina_cost:
		push_warning("体力不足，无法搜刮")
		return false

	# 消耗体力
	if player:
		player.stamina -= stamina_cost
		player.stamina_changed.emit(player.stamina)

	# 消耗时间
	if GameManager.instance:
		GameManager.instance.consume_time(search_time)

	# 生成掉落
	var items: Array = _generate_loot()

	# 添加到物品栏
	for item in items:
		if Inventory.instance:
			Inventory.instance.add_item(item["item_id"], item["count"])

	is_searched = true
	searched.emit(self, items)

	# 更新UI提示
	if is_searched:
		GameUI.hide_interact_prompt()

	return true

## 生成掉落物品
func _generate_loot() -> Array:
	var items: Array = []
	for loot in loot_table:
		var chance: float = loot.get("chance", 1.0)
		if randf() < chance:
			items.append({
				"item_id": loot["item_id"],
				"count": loot.get("count", 1)
			})
	return items

## 获取玩家引用
func _get_player() -> Player:
	var tree: SceneTree = get_tree()
	if not tree:
		return null
	return tree.get_first_node_in_group("player") as Player
