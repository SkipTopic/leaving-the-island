@tool
class_name HouseProp
extends StaticBody2D
## 房屋道具：贴图可换（检查器里换 PNG 立即在编辑器预览），碰撞框可调。

## 房屋贴图
@export var house_texture: Texture2D:
	set(value):
		house_texture = value
		_update_visual()
## 碰撞框大小
@export var collider_size := Vector2(150, 180):
	set(value):
		collider_size = value
		_update_collider()
## 碰撞框偏移
@export var collider_offset := Vector2(0, -100):
	set(value):
		collider_offset = value
		_update_collider()

@onready var sprite: Sprite2D = $Sprite
@onready var shape: CollisionShape2D = $Shape


func _ready() -> void:
	_update_visual()
	_update_collider()


func _update_visual() -> void:
	if not is_inside_tree() or house_texture == null:
		return
	sprite.texture = house_texture
	sprite.offset = Vector2(0, -house_texture.get_height() / 2.0)


func _update_collider() -> void:
	if not is_inside_tree():
		return
	var rect := RectangleShape2D.new()
	rect.size = collider_size
	shape.shape = rect
	shape.position = collider_offset
