class_name FlyingBird
extends CharacterBody2D
## 低飞鸟（日记钦定）：天上盘旋，玩家靠近俯冲啄一下就跑。

@export var max_hp := 6
@export var contact_damage := 1
@export_range(40.0, 200.0) var dive_speed := 150.0
@export_range(20.0, 200.0) var detect_radius := 80.0

enum State { HOVER, DIVE, REST }
var hp: int
var state := State.HOVER
var _home := Vector2.ZERO
var _t := 0.0
var _rest_t := 0.0
var _dir := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 1
	hp = max_hp
	_home = global_position


func _physics_process(delta: float) -> void:
	if state == State.HOVER:
		_t += delta
		velocity = Vector2(sin(_t * 1.7) * 30.0, cos(_t * 1.3) * 18.0)
		global_position.y = _home.y + sin(_t * 2.0) * 4.0
		move_and_slide()
		var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
		if player != null and player.is_free() and global_position.distance_to(player.global_position) < detect_radius:
			state = State.DIVE
			_dir = (player.global_position + Vector2(0, -8) - global_position).normalized()
			sprite.flip_h = _dir.x < 0
	elif state == State.DIVE:
		velocity = _dir * dive_speed
		move_and_slide()
		if is_on_wall() or is_on_floor():
			_rest()
		var player2 := get_tree().get_first_node_in_group("player") as PlayerCharacter
		if player2 != null and global_position.distance_to(player2.global_position) < 14.0:
			player2.take_damage(contact_damage, global_position)
			_rest()
	elif state == State.REST:
		velocity = Vector2.ZERO
		_rest_t -= delta
		if _rest_t <= 0.0:
			state = State.HOVER


func _rest() -> void:
	state = State.REST
	_rest_t = 1.2


func take_hit(dmg: int, from_pos: Vector2) -> void:
	hp -= dmg
	velocity = (global_position - from_pos).normalized() * 120.0
	_rest()
	if hp <= 0:
		remove_from_group("enemies")
		collision_layer = 0
		collision_mask = 0
		Pickup.spawn(get_parent(), global_position, "stone")
		var tw := create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)
