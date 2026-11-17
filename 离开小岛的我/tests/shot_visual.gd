extends Node
## 视觉验收截图 runner（非无头跑，窗口化）：
## 依次加载 室内/小镇/世界地图，各截一张存到 Zcode工作区域/00_思考过程/。
## 运行: godot --path <工程> res://tests/shot_visual.tscn

const OUT := "res://../Zcode工作区域/00_思考过程/"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _shots()
	get_tree().quit(0)


func _shots() -> void:
	# --- 室内（跳过开场，直接 PLAYING 状态）---
	Game.set_flag("intro_wake_done", true)
	var home: Node = load("res://scenes/town/home_interior.tscn").instantiate()
	get_tree().root.add_child(home)
	await _wait(1.0)
	_focus_cam(home)
	await _snap("验收截图_室内小屋.png")
	# --- 对话气球预览（验证字号/行距；参数在 balloon 检查器"对话显示"组）---
	var balloon: CanvasLayer = DialogueManager.show_dialogue_balloon(
		load("res://resources/dialogue/town/intro.dialogue"), "out_1")
	await _wait(1.6)
	await _snap("验收截图_对话气球.png")
	balloon.queue_free()
	Game.state = Game.State.PLAYING
	home.queue_free()
	await _wait(0.2)

	# --- 小镇 ---
	var town: Node = load("res://scenes/town/town.tscn").instantiate()
	get_tree().root.add_child(town)
	await _wait(1.0)
	_focus_cam(town)
	await _snap("验收截图_小镇草地.png")
	# --- 房前贴脸（验证 Y-sort：玩家紧贴我家台阶应完整可见，不被房子盖住）---
	var tp := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if tp != null:
		tp.global_position = Vector2(240, 518)  # 我家门口，紧贴台阶下沿
		if tp.has_node("Camera"):
			tp.get_node("Camera").reset_smoothing()
		await _wait(0.4)
		await _snap("验收截图_房前贴脸.png")
	town.queue_free()
	await _wait(0.2)

	# --- 世界地图 ---
	var wm: Node = load("res://scenes/world/worldmap.tscn").instantiate()
	get_tree().root.add_child(wm)
	await _wait(1.0)
	_focus_cam(wm)
	await _snap("验收截图_世界地图.png")
	wm.queue_free()
	await _wait(0.2)

	# --- 山道公路（南端起点，看柏油+虚线+蜿蜒）---
	var mt: Node = load("res://scenes/mountain/mountain_road.tscn").instantiate()
	get_tree().root.add_child(mt)
	await _wait(1.0)
	_focus_cam(mt)
	await _snap("验收截图_山道公路.png")
	mt.queue_free()
	await _wait(0.2)


func _focus_cam(scene: Node) -> void:
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if player != null and player.has_node("Camera"):
		var cam: Camera2D = player.get_node("Camera")
		cam.reset_smoothing()


func _wait(sec: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < int(sec * 1000):
		await get_tree().process_frame


func _snap(fname: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(OUT + fname)
	var err := img.save_png(path)
	print("[shot] %s → %s" % [fname, "OK" if err == OK else error_string(err)])
