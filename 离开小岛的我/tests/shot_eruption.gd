extends Node
## 序章爆发/灰烬视觉验收截图 → 存 00_思考过程。
## 运行: godot --path <项目> res://tests/shot_eruption.tscn （非无头）

const OUT_DIR := "Zcode工作区域/00_思考过程/"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _frames(5)
	var base := ProjectSettings.globalize_path("res://").path_join("../" + OUT_DIR)

	# --- 图1：爆发后小镇（灰天+黑雪）---
	Game.set_flag("eruption_seen", true)
	var town: Node = load("res://scenes/town/town.tscn").instantiate()
	get_tree().root.add_child(town)
	await _frames(10)
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	player.global_position = Vector2(15 * 32, 18 * 32)
	player.camera.reset_smoothing()
	await _frames(50)  # 等黑雪铺满半空
	_shot(base.path_join("M4_爆发后小镇.png"))
	town.queue_free()
	await _frames(3)

	# --- 图2：隧道火柴光斑 ---
	Inventory.add_item("match", 1)
	var mountain: Node = load("res://scenes/mountain/mountain_road.tscn").instantiate()
	get_tree().root.add_child(mountain)
	await _frames(5)
	player = mountain.find_child("Player", true, false) as PlayerCharacter
	player.global_position = Vector2(15 * 32, 100 * 32)
	player.camera.reset_smoothing()
	await _frames(90)  # 等黑暗渐入完成
	_shot(base.path_join("M4_隧道光斑.png"))

	# --- 图3：山口灰烬（浓）---
	player.global_position = Vector2(15 * 32, 30 * 32)
	player.camera.reset_smoothing()
	await _frames(200)  # 粒子是全局坐标，瞬移后要等新粒子飘进视野（~2.5s）
	_shot(base.path_join("M4_山口灰烬.png"))
	mountain.queue_free()
	await _frames(3)
	get_tree().quit(0)


func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("已存: ", path)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
