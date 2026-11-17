class_name Pickup
extends Area2D
## 地面拾取物：走过去自动进背篓。图标随 item_id 自动带出。

## 物品ID（对应 ItemDB）
@export var item_id := "stone"
## 数量
@export var amount := 1

var _time := 0.0

@onready var sprite: Sprite2D = $Sprite


static func spawn(parent: Node, pos: Vector2, id: String, count := 1) -> void:
	var p: Pickup = load("res://scenes/actors/pickup.tscn").instantiate()
	p.item_id = id
	p.amount = count
	p.position = pos
	parent.add_child(p)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4  # 玩家层
	var icon_path: String = ItemDB.get_item(item_id)["icon"]
	if ResourceLoader.exists(icon_path):
		sprite.texture = load(icon_path)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	sprite.position.y = -6.0 + sin(_time * 3.0) * 1.5


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	Inventory.add_item(item_id, amount)
	Events.notify.emit("获得 %s x%d" % [ItemDB.display_name(item_id), amount])
	queue_free()
