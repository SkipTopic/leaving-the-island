class_name Boar
extends CharacterBody2D
## 野猪（日记钦定 HP:10）：巡逻 → 警觉 → 冲撞 → 硬直循环。死后掉石子。
## 数值全部在检查器里调。

@export_group("数值")
@export var max_hp := 10 ## 血量
@export var contact_damage := 2 ## 冲撞撞到玩家的伤害
@export var drop_item := "stone" ## 死亡掉落的物品
@export var drop_count := 2 ## 掉落数量

@export_group("行为")
@export_range(10.0, 120.0) var patrol_speed := 38.0 ## 巡逻速度
@export_range(80.0, 400.0) var charge_speed := 195.0 ## 冲撞速度
@export_range(20.0, 300.0) var detect_radius := 95.0 ## 发现玩家距离
@export_range(0.1, 1.0) var alert_time := 0.35 ## 警觉停顿（秒）
@export_range(0.1, 2.0) var charge_time := 0.6 ## 冲撞持续（秒）
@export_range(0.1, 3.0) var cooldown_time := 0.9 ## 冲撞后硬直（秒）
@export_range(2.0, 16.0) var walk_fps := 8.0 ## 走路动画帧率

@export_group("贴图")
@export var tex_walk_1: Texture2D = preload("res://assets/sprites/custom/boar_walk_1.png")
@export var tex_walk_2: Texture2D = preload("res://assets/sprites/custom/boar_walk_2.png")
@export var tex_charge: Texture2D = preload("res://assets/sprites/custom/boar_charge.png")

enum State { PATROL, ALERT, CHARGE, COOLDOWN, DEAD }

var hp: int = max_hp
var state := State.PATROL

var _state_t := 0.0
var _wander_t := 0.0
var _wander_dir := Vector2.ZERO
var _charge_dir := Vector2.ZERO
var _anim_t := 0.0
var _flash_t := 0.0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8   # 敌人层
	collision_mask = 1 | 4  # 世界 + 玩家
	hp = max_hp


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_flash_t = maxf(0.0, _flash_t - delta)
	sprite.modulate = Color(3.0, 3.0, 3.0) if _flash_t > 0.0 else Color.WHITE

	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter

	match state:
		State.PATROL:
			_wander_t -= delta
			if _wander_t <= 0.0:
				if randf() < 0.55:
					_wander_dir = Vector2.ZERO
					_wander_t = randf_range(0.8, 1.8)
				else:
					_wander_dir = Vector2.from_angle(randf() * TAU)
					_wander_t = randf_range(0.7, 1.4)
			velocity = _wander_dir * patrol_speed
			move_and_slide()
			if player != null and player.is_free() \
					and global_position.distance_to(player.global_position) < detect_radius:
				state = State.ALERT
				_state_t = alert_time
		State.ALERT:
			velocity = Vector2.ZERO
			_state_t -= delta
			if player != null:
				sprite.flip_h = player.global_position.x < global_position.x
			if _state_t <= 0.0:
				state = State.CHARGE
				_state_t = charge_time
				_charge_dir = (player.global_position - global_position).normalized() if player != null else Vector2.LEFT
				sprite.texture = tex_charge
		State.CHARGE:
			velocity = _charge_dir * charge_speed
			move_and_slide()
			_state_t -= delta
			if player != null and global_position.distance_to(player.global_position) < 16.0:
				player.take_damage(contact_damage, global_position)
				_enter_cooldown(cooldown_time)
			elif _state_t <= 0.0 or is_on_wall():
				_enter_cooldown(cooldown_time)
		State.COOLDOWN:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			move_and_slide()
			_state_t -= delta
			if _state_t <= 0.0:
				state = State.PATROL
				sprite.texture = tex_walk_1

	_animate(delta)


func _enter_cooldown(t: float) -> void:
	state = State.COOLDOWN
	_state_t = t
	sprite.texture = tex_walk_1


func take_hit(dmg: int, from_pos: Vector2) -> void:
	if state == State.DEAD:
		return
	hp -= dmg
	_flash_t = 0.12
	velocity = (global_position - from_pos).normalized() * 150.0
	_enter_cooldown(0.55)
	if hp <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	for i in drop_count:
		Pickup.spawn(get_parent(), global_position + Vector2(randf_range(-10, 10), randf_range(-6, 6)), drop_item)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)


func _animate(delta: float) -> void:
	if absf(velocity.x) > 4.0:
		sprite.flip_h = velocity.x < 0.0
	if velocity.length() > 5.0 and state != State.CHARGE:
		_anim_t += delta * walk_fps
		sprite.texture = tex_walk_1 if int(_anim_t) % 2 == 0 else tex_walk_2
