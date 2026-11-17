extends Node2D
## 世界地图运行时根脚本（烘焙后 worldmap.tscn 用它）。
## 负责：状态、HUD、落点标记。地点进出自带在 LocationGate 里。

func _ready() -> void:
	Game.state = Game.State.PLAYING
	add_child(GameHUD.new())
	_apply_pending_spawn()


func _apply_pending_spawn() -> void:
	if Game.pending_spawn == "":
		return
	var marker := find_child(Game.pending_spawn, true, false) as Marker2D
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if marker != null and player != null:
		player.global_position = marker.global_position
	Game.pending_spawn = ""
