extends Node2D
## 办公区运行时根脚本：状态/HUD/落点/门禁开门/矿车/结局跳转。

var _doors_cleared := false
var _riding := false
var _ending_busy := false


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


func _process(_delta: float) -> void:
	# 门禁解锁 → 移除三扇门（检查器里看得见，解锁后消失）
	# 上帝模式（调试）同样开门——不用解谜直接看三房间
	if not _doors_cleared and (Game.get_flag("doors_open") != null or Game.god_mode):
		_doors_cleared = true
		for i in 3:
			var door := find_child("Door_%d" % i, true, false)
			if door != null:
				door.queue_free()
	# 矿车请求 → 去空镇揭示
	if not _riding and Game.get_flag("ride_requested") != null:
		_riding = true
		Game.set_flag("ride_requested", false)
		Game.pending_spawn = "FromMinecart"
		Game.change_scene("res://scenes/town/town_reveal.tscn")
	# 空镇调查完毕 → 自动回办公区
	if Game.get_flag("reveal_done") != null and Game.get_flag("returned_after_reveal") == null \
			and Game.current_scene_path.contains("office"):
		Game.set_flag("returned_after_reveal", true)
		Game.pending_spawn = "FromReveal"
		Game.change_scene("res://scenes/office/office.tscn")
	# 结局 → 结局场景（staff roll 在结局场景里播，滚完自动回标题）
	var ending = Game.get_flag("ending")
	if ending != null and not _ending_busy:
		_ending_busy = true
		var path := "res://scenes/ending/ending_silence.tscn"
		if int(ending) == 2:
			path = "res://scenes/ending/ending_reply.tscn"
		print("[M3] 结局触发 → ", path)
		await get_tree().create_timer(2.5).timeout
		Game.pending_spawn = ""
		Game.change_scene(path)
