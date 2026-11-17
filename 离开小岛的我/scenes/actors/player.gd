class_name PlayerCharacter
extends CharacterBody2D
## 主角：8向移动 / 砍刀三段连击 / 弹弓 / 交互 / 受伤无敌帧。
## 场景结构见 player.tscn；所有手感参数都在检查器里（带中文注释）。

@export_group("移动")
## 移动速度（像素/秒）
@export_range(40.0, 400.0) var move_speed := 130.0
## 走路动画帧率
@export_range(4.0, 20.0) var walk_fps := 9.0

@export_group("战斗")
@export var max_hp := 20 ## 血量上限
@export var attack_time := 0.28 ## 每段挥砍时长（秒）
@export var attack_damages: Array[int] = [4, 4, 5] ## 三段连击各自伤害
@export var attack_push := 46.0 ## 挥砍期间向前顶的速度
@export var stone_damage := 2 ## 弹弓石子伤害
@export_range(0.1, 2.0) var invuln_time := 0.8 ## 受伤无敌帧（秒）
@export_range(60.0, 400.0) var knockback_force := 170.0 ## 受击击退力度

enum State { MOVE, ATTACK, HURT, DEAD }

var hp: int = max_hp
var facing := Vector2.DOWN
var state := State.MOVE
## 出生点（@export 必须保留：烘焙场景要把它存进 tscn，
## 否则运行时是 (0,0)，开场会把玩家传进墙里卡死——踩过）
@export var spawn_point := Vector2.ZERO

var _attack_t := 0.0
var _attack_stage := 0
var _combo_queued := false
var _attack_hit: Array = []
var _hurt_t := 0.0
var _knockback := Vector2.ZERO
var _invuln := 0.0
var _slingshot_cd := 0.0
var _anim_t := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var slash_pivot: Node2D = $SlashPivot
@onready var slash_sprite: Sprite2D = $SlashPivot/Slash
@onready var hitbox: Area2D = $SlashPivot/Hitbox
@onready var reach: Area2D = $Reach
@onready var camera: Camera2D = $Camera

# Pipoya 行序：0朝下 1朝左 2朝右 3朝上；每行3帧：步1/站/步2
const _WALK_SEQ := [0, 1, 2, 1]


func _ready() -> void:
	add_to_group("player")
	collision_layer = 4   # 玩家层
	collision_mask = 1 | 8  # 世界 + 敌人
	hp = max_hp
	Events.player_hp_changed.emit(hp, max_hp)


func _physics_process(delta: float) -> void:
	_invuln = maxf(0.0, _invuln - delta)
	_slingshot_cd = maxf(0.0, _slingshot_cd - delta)
	sprite.modulate.a = 0.55 if (_invuln > 0.0 and int(_invuln * 12.0) % 2 == 0) else 1.0

	match state:
		State.MOVE:
			_move_state(delta)
		State.ATTACK:
			_attack_state(delta)
		State.HURT:
			_hurt_state(delta)
		State.DEAD:
			pass

	if state != State.DEAD:
		_animate(delta)
		_update_prompt()


func is_free() -> bool:
	return state != State.DEAD and Game.state == Game.State.PLAYING


func _move_state(delta: float) -> void:
	if not is_free():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * move_speed
	move_and_slide()
	if input != Vector2.ZERO:
		if absf(input.x) >= absf(input.y):
			facing = Vector2(signf(input.x), 0)
		else:
			facing = Vector2(0, signf(input.y))
	if Input.is_action_just_pressed("attack"):
		_start_attack()
	elif Input.is_action_just_pressed("slingshot"):
		_fire_stone()
	elif Input.is_action_just_pressed("interact"):
		_try_interact()


func _start_attack() -> void:
	state = State.ATTACK
	_attack_stage = 0
	_attack_t = attack_time
	_combo_queued = false
	_attack_hit.clear()
	slash_pivot.rotation = facing.angle() + PI / 2.0
	hitbox.monitoring = true


func _attack_state(delta: float) -> void:
	_attack_t -= delta
	var elapsed := attack_time - _attack_t
	slash_sprite.visible = elapsed > 0.03 and elapsed < 0.2
	if elapsed > 0.05 and elapsed < 0.2:
		var targets := hitbox.get_overlapping_bodies() + hitbox.get_overlapping_areas()
		for t in targets:
			if t.is_in_group("enemies") and not _attack_hit.has(t):
				_attack_hit.append(t)
				t.take_hit(attack_damages[_attack_stage], global_position)
	velocity = facing * attack_push if elapsed < 0.14 else Vector2.ZERO
	move_and_slide()
	if Input.is_action_just_pressed("attack") and elapsed > attack_time * 0.4:
		_combo_queued = true
	if _attack_t <= 0.0:
		hitbox.monitoring = false
		slash_sprite.visible = false
		if _combo_queued and _attack_stage < attack_damages.size() - 1:
			_attack_stage += 1
			_attack_t = attack_time
			_attack_hit.clear()
			hitbox.monitoring = true
		else:
			state = State.MOVE


func _hurt_state(delta: float) -> void:
	_hurt_t -= delta
	velocity = _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)
	move_and_slide()
	if _hurt_t <= 0.0:
		state = State.MOVE


func take_damage(amount: int, from_pos: Vector2) -> void:
	if Game.god_mode:
		return  # 上帝模式（调试）无敌
	if _invuln > 0.0 or state == State.DEAD:
		return
	hp = maxi(0, hp - amount)
	Events.player_damaged.emit(amount)
	Events.player_hp_changed.emit(hp, max_hp)
	_invuln = invuln_time
	if hp <= 0:
		_die()
		return
	state = State.HURT
	_hurt_t = 0.18
	_knockback = (global_position - from_pos).normalized() * knockback_force


func heal(amount: int) -> void:
	if state == State.DEAD:
		return
	hp = mini(max_hp, hp + amount)
	Events.player_healed.emit(amount)
	Events.player_hp_changed.emit(hp, max_hp)


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	Events.player_died.emit()
	Events.prompt_changed.emit("")
	slash_sprite.visible = false
	sprite.modulate.a = 0.4
	await get_tree().create_timer(0.9).timeout
	# 眼前一黑——醒来时又躺回了自家门口
	Game.change_scene(get_tree().current_scene.scene_file_path)


func _fire_stone() -> void:
	if _slingshot_cd > 0.0:
		return
	if Inventory.count("stone") <= 0:
		Events.notify.emit("口袋里没有石子了。")
		return
	Inventory.remove_item("stone")
	_slingshot_cd = 0.45
	StoneProjectile.spawn(get_tree(), global_position + Vector2(0, -12) + facing * 10.0, facing)


func _try_interact() -> void:
	var target := _nearest_interactable()
	if target != null:
		target.interact(self)


func _nearest_interactable() -> Node:
	var best: Node = null
	var best_d := INF
	for a in reach.get_overlapping_areas():
		var owner_node: Node = a if a.has_method("interact") else a.get_parent()
		if owner_node == null or not owner_node.has_method("interact"):
			continue
		var d: float = owner_node.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = owner_node
	return best


func _update_prompt() -> void:
	if not is_free():
		return
	var target := _nearest_interactable()
	if target != null:
		var text: String = target.prompt_text() if target.has_method("prompt_text") else "交谈"
		Events.prompt_changed.emit(text)
	else:
		Events.prompt_changed.emit("")


func _animate(delta: float) -> void:
	var row := 0
	if facing == Vector2.LEFT:
		row = 1
	elif facing == Vector2.RIGHT:
		row = 2
	elif facing == Vector2.UP:
		row = 3
	if velocity.length() > 5.0 and state != State.ATTACK:
		_anim_t += delta * walk_fps
		sprite.frame = row * 3 + _WALK_SEQ[int(_anim_t) % 4]
	else:
		_anim_t = 0.0
		sprite.frame = row * 3 + 1
