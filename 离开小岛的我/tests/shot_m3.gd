extends Node
## M3 内容验收截图：新NPC/钢琴/两个结局场景 → 存 00_思考过程。
## 运行: godot --path <项目> res://tests/shot_m3.tscn （非无头）

const OUT_DIR := "Zcode工作区域/00_思考过程/"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _frames(5)
	var base := ProjectSettings.globalize_path("res://").path_join("../" + OUT_DIR)

	# --- 小镇：码头六叔 ---
	var town: Node = load("res://scenes/town/town.tscn").instantiate()
	get_tree().root.add_child(town)
	await _frames(5)
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	player.global_position = Vector2(10 * 32, 24 * 32)
	player.camera.reset_smoothing()
	await _frames(10)
	_shot(base.path_join("M3_码头六叔.png"))
	# 会堂钢琴+阿蓝
	player.global_position = Vector2(38 * 32, 10 * 32)
	player.camera.reset_smoothing()
	await _frames(10)
	_shot(base.path_join("M3_会堂阿蓝.png"))
	town.queue_free()
	await _frames(3)

	# --- 结局一（auto_play 关掉只看布景）---
	var sil: Node = load("res://scenes/ending/ending_silence.tscn").instantiate()
	sil.auto_play = false
	get_tree().root.add_child(sil)
	await _frames(10)
	var p2 := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if p2 != null:
		p2.global_position = Vector2(384, 380)
		p2.camera.reset_smoothing()
	await _frames(5)
	_shot(base.path_join("M3_结局一沉默.png"))
	sil.queue_free()
	await _frames(3)

	# --- 结局二 ---
	var rep: Node = load("res://scenes/ending/ending_reply.tscn").instantiate()
	rep.auto_play = false
	get_tree().root.add_child(rep)
	await _frames(10)
	var p3 := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if p3 != null:
		p3.global_position = Vector2(320, 180)
		p3.camera.reset_smoothing()
	await _frames(5)
	_shot(base.path_join("M3_结局二回信.png"))
	rep.queue_free()
	await _frames(3)
	get_tree().quit(0)


func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("已存: ", path)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
