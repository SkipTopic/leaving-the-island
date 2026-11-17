class_name StoneProjectile
extends Area2D
## 弹弓石子：直线飞行，命中野猪或撞墙即消失。

const SPEED := 270.0
const LIFETIME := 0.8
const DAMAGE := 2

var dir := Vector2.RIGHT

var _life := LIFETIME


static func spawn(tree: SceneTree, pos: Vector2, direction: Vector2) -> void:
	var s := StoneProjectile.new()
	s.dir = direction.normalized()
	s.position = pos
	s.name = "StoneProjectile"
	var scene_root := tree.current_scene
	if scene_root != null:
		scene_root.add_child(s)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 8  # 世界 + 敌人
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)

	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/custom/stone.png")
	sprite.rotation = dir.angle()
	add_child(sprite)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += dir * SPEED * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_hit(DAMAGE, global_position)
	queue_free()
