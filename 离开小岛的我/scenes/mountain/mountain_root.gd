extends Node2D
## 上山之路运行时根脚本（烘焙后 mountain_road.tscn 用它）。
## 负责：状态/HUD/落点/隧道黑暗+火柴灯/灯亮演出/落石/南北出口/灰烬（越近山口越浓）。

const DARK_COLOR := Color(0.13, 0.14, 0.2)
const TUNNEL_Y := Vector2(90, 114)  # 隧道区间（格）
const ASH_FALL := preload("res://scenes/fx/ash_fall.tscn")

var _modulate: CanvasModulate
var _light: PointLight2D
var _ash: AshFall
var _player: PlayerCharacter
var _flicker_t := 0.0
var _lamp_done := false
var _rock_done := false
var _south_busy := false
var _north_busy := false
var _gate_cleared := false


## 优先取本场景的玩家（多场景同活的测试环境下 group 查找会拿错人）
func _scene_player() -> PlayerCharacter:
	var p := find_child("Player", true, false) as PlayerCharacter
	if p == null:
		p = get_tree().get_first_node_in_group("player") as PlayerCharacter
	return p


func _ready() -> void:
	Game.state = Game.State.PLAYING
	add_child(GameHUD.new())
	_apply_pending_spawn()
	_player = _scene_player()

	_modulate = CanvasModulate.new()
	_modulate.color = Color.WHITE
	add_child(_modulate)

	_light = PointLight2D.new()
	_light.enabled = false
	_light.energy = 1.2
	_light.texture = load("res://assets/sprites/custom/light_spot.png")  # 抖动像素光斑
	if _player != null:
		_player.add_child(_light)

	# 爆发的灰还在下：挂在玩家头顶跟随视角，越往北（近山口）越浓
	_ash = ASH_FALL.instantiate()
	_ash.name = "AshFall"
	_ash.flake_texture = load("res://assets/sprites/custom/ash_speck.png")
	_ash.flake_color = Color(0.2, 0.17, 0.15, 0.85)
	_ash.density = 10.0
	_ash.wind = 14.0
	_ash.width = 800.0
	if _player != null:
		_player.add_child(_ash)
		_ash.position = Vector2(0, -230)

	for gate_name in [["SouthExit", _on_south], ["NorthExit", _on_north]]:
		var gate := get_node_or_null(gate_name[0]) as Area2D
		if gate != null:
			gate.body_entered.connect(gate_name[1])
	for trig_name in [["Trigger_灯亮", _on_lamp_trigger], ["Trigger_落石", _on_rock_trigger]]:
		var trig := get_node_or_null("World/Props/../" + trig_name[0]) as Area2D
		if trig == null:
			trig = find_child(trig_name[0], true, false) as Area2D
		if trig != null:
			trig.body_entered.connect(trig_name[1])


func _apply_pending_spawn() -> void:
	if Game.pending_spawn == "":
		return
	var marker := find_child(Game.pending_spawn, true, false) as Marker2D
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if marker != null and player != null:
		player.global_position = marker.global_position
	Game.pending_spawn = ""


func _process(delta: float) -> void:
	# 观测站大门：密码开锁（crater_gate_open）或上帝模式 → 移除门体
	if not _gate_cleared and (Game.get_flag("crater_gate_open") != null or Game.god_mode):
		_gate_cleared = true
		var gate := find_child("CraterGate", true, false)
		if gate != null:
			gate.queue_free()
	var player := _player if _player != null else _scene_player()
	if player == null:
		return
	var cell_y := int(player.global_position.y / 32.0)
	var in_tunnel := cell_y >= TUNNEL_Y.x and cell_y <= TUNNEL_Y.y
	var target := DARK_COLOR if in_tunnel else Color.WHITE
	_modulate.color = _modulate.color.lerp(target, 6.0 * delta)
	# 隧道里有火柴/手电 → 点亮周身（火苗抖动：能量轻微起伏）
	_light.enabled = in_tunnel and Inventory.count("match") > 0
	_light.texture_scale = 2.2
	_flicker_t += delta
	_light.energy = 1.2 + sin(_flicker_t * 7.0) * 0.06 + sin(_flicker_t * 13.7) * 0.04
	# 灰烬浓度：cell_y 小=北=近山口 → 更浓更黑
	if _ash != null:
		var north := clampf(1.0 - float(cell_y) / 170.0, 0.0, 1.0)
		_ash.density = lerpf(6.0, 44.0, north * north)
		_ash.color = Color(0.2, 0.17, 0.15, 0.85).lerp(Color(0.45, 0.42, 0.4, 0.5), 1.0 - north)


func _on_south(body: Node2D) -> void:
	if _south_busy or not body.is_in_group("player"):
		return
	_south_busy = true
	Game.pending_spawn = "FromCrater"
	Game.change_scene("res://scenes/world/worldmap.tscn")


func _on_north(body: Node2D) -> void:
	if _north_busy or not body.is_in_group("player"):
		return
	_north_busy = true
	Game.pending_spawn = "FromMountain"
	Game.change_scene("res://scenes/office/office.tscn")


func _on_lamp_trigger(body: Node2D) -> void:
	if _lamp_done or not body.is_in_group("player"):
		return
	_lamp_done = true
	StageDirector.shake_camera(3.0, 0.5)
	DialogueManager.show_dialogue_balloon(
		load("res://resources/dialogue/mountain/observatory.dialogue"), "lights")


func _on_rock_trigger(body: Node2D) -> void:
	if _rock_done or not body.is_in_group("player"):
		return
	_rock_done = true
	_drop_rocks()


## 落石：三块石头从头顶砸下（纯演出+判定，不生成节点残留）
func _drop_rocks() -> void:
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if player == null:
		return
	StageDirector.shake_camera(5.0, 0.6)
	for i in 3:
		var rock := Sprite2D.new()
		rock.texture = load("res://assets/sprites/custom/stone.png")
		rock.scale = Vector2(2.5, 2.5)
		var target := player.global_position + Vector2(randf_range(-40, 40), randf_range(-10, 10))
		rock.position = target + Vector2(0, -160)
		add_child(rock)
		var tw := create_tween()
		tw.tween_property(rock, "position", target, 0.35).set_delay(i * 0.18)
		tw.tween_callback(func():
			if is_instance_valid(player) and player.global_position.distance_to(target) < 26.0:
				player.take_damage(3, target)
			rock.queue_free())
