extends Node2D
## 小镇运行时根脚本（烘焙后 town.tscn 用的就是它）。
## 负责：游戏状态、HUD 挂载、落点标记应用、北出口 → 世界地图、
##       爆发后视觉（灰天 + 黑雪，由 eruption_seen flag 驱动）。

const ASH_FALL := preload("res://scenes/fx/ash_fall.tscn")

var _exit_busy := false


func _ready() -> void:
	Game.state = Game.State.PLAYING
	add_child(GameHUD.new())
	_apply_pending_spawn()
	_apply_eruption_visuals()
	var exit_area := get_node_or_null("NorthExit") as Area2D
	if exit_area != null:
		exit_area.body_entered.connect(_on_exit_touched)


## 序章爆发之后：天变灰，黑雪一直下（挂玩家头顶跟随视角）。
func _apply_eruption_visuals() -> void:
	if Game.get_flag("eruption_seen") == null:
		return
	var sky := CanvasModulate.new()
	sky.name = "AshSky"
	sky.color = Color(0.68, 0.64, 0.66)
	add_child(sky)
	var ash: AshFall = ASH_FALL.instantiate()
	ash.name = "AshFall"
	ash.flake_texture = load("res://assets/sprites/custom/ash_flake.png")
	ash.flake_color = Color(0.15, 0.13, 0.14, 0.9)
	ash.density = 36.0
	ash.wind = -16.0
	ash.width = 900.0
	var player := find_child("Player", true, false) as PlayerCharacter
	if player == null:
		player = get_tree().get_first_node_in_group("player") as PlayerCharacter
	if player != null:
		player.add_child(ash)
		ash.position = Vector2(0, -230)
	else:
		ash.position = Vector2(22 * 32, -40)
		add_child(ash)


## 从世界地图回来时，把玩家放到 pending_spawn 指定的 Marker2D 上。
func _apply_pending_spawn() -> void:
	if Game.pending_spawn == "":
		return
	var marker := find_child(Game.pending_spawn, true, false) as Marker2D
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if marker != null and player != null:
		player.global_position = marker.global_position
	Game.pending_spawn = ""


func _on_exit_touched(body: Node2D) -> void:
	if _exit_busy or not body.is_in_group("player"):
		return
	_exit_busy = true
	Game.set_flag("left_town_once", true)
	Game.pending_spawn = "FromTown"
	Game.change_scene("res://scenes/world/worldmap.tscn")
