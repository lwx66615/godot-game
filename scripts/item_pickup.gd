extends Area2D
class_name ItemPickup

@export var item_id: String = ""
@export var count: int = 1

signal item_picked_up(item_id: String, count: int)

func _ready():
	add_to_group("item_pickup")
	collision_layer = 4  # interactable层
	collision_mask = 1   # 检测player层

	# 添加碰撞形状（必须，否则无法检测玩家）
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	add_child(collision)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body is Player and Inventory.instance:
		var item_name: String = Inventory.instance.get_item_name(item_id)
		GameUI.show_interact_prompt("按E拾取 " + item_name)
		GameUI.set_nearby_item(self, true)

func _on_body_exited(body: Node2D):
	if body is Player:
		GameUI.hide_interact_prompt()
		GameUI.set_nearby_item(self, false)

func pickup() -> bool:
	if Inventory.instance and Inventory.instance.add_item(item_id, count):
		item_picked_up.emit(item_id, count)
		queue_free()
		return true
	return false
