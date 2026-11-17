@tool
class_name TreeProp
extends StaticBody2D
## 树道具：贴图可换、可在编辑器里随意拖拽摆正。

## 树贴图
@export var tree_texture: Texture2D:
	set(value):
		tree_texture = value
		_update_visual()
## 碰撞框大小（树干根部）
@export var collider_size := Vector2(14, 10)
## 贴图纵向偏移（节点=树根位置）
@export var sprite_offset := Vector2(0, -42)

@onready var sprite: Sprite2D = $Sprite
@onready var shape: CollisionShape2D = $Shape


func _ready() -> void:
	_update_visual()


func _update_visual() -> void:
	if not is_inside_tree() or tree_texture == null:
		return
	sprite.texture = tree_texture
	sprite.offset = sprite_offset
