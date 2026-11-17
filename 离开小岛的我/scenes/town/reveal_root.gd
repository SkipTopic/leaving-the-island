extends Node2D
## 空镇揭示运行时根脚本（烘焙后 town_reveal.tscn 用它）。
## 负责：夜色小镇状态、进图自动播矿车独白、床底洞返回办公区、稀疏灰烬氛围。

const ASH_FALL := preload("res://scenes/fx/ash_fall.tscn")

var _ride_started := false


func _ready() -> void:
	Game.state = Game.State.PLAYING
	add_child(GameHUD.new())
	_apply_pending_spawn()
	_apply_ash()
	# 第一次乘矿车抵达：自动播揭示独白
	if Game.get_flag("reveal_ride_done") == null and not _ride_started:
		_ride_started = true
		Game.state = Game.State.DIALOGUE
		DialogueManager.show_dialogue_balloon(
			preload("res://resources/dialogue/town/reveal.dialogue"), "ride")
		await DialogueManager.dialogue_ended
		Game.state = Game.State.PLAYING


## 空镇的夜里也飘着灰（更稀、更慢，氛围用）。
func _apply_ash() -> void:
	var ash: AshFall = ASH_FALL.instantiate()
	ash.name = "AshFall"
	ash.flake_texture = load("res://assets/sprites/custom/ash_flake.png")
	ash.flake_color = Color(0.55, 0.55, 0.6, 0.5)
	ash.density = 12.0
	ash.wind = -10.0
	ash.width = 800.0
	var player := find_child("Player", true, false) as PlayerCharacter
	if player == null:
		player = get_tree().get_first_node_in_group("player") as PlayerCharacter
	if player != null:
		player.add_child(ash)
		ash.position = Vector2(0, -230)
	else:
		ash.position = Vector2(22 * 32, -40)
		add_child(ash)


func _apply_pending_spawn() -> void:
	if Game.pending_spawn == "":
		return
	var marker := find_child(Game.pending_spawn, true, false) as Marker2D
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if marker != null and player != null:
		player.global_position = marker.global_position
	Game.pending_spawn = ""


func _process(_delta: float) -> void:
	# 在床底洞交互后（return_requested）→ 回办公区算总账
	if Game.get_flag("return_requested") != null and Game.get_flag("returned_after_reveal") == null:
		Game.set_flag("returned_after_reveal", true)
		Game.set_flag("return_requested", false)
		Game.pending_spawn = "FromReveal"
		Game.change_scene("res://scenes/office/office.tscn")
