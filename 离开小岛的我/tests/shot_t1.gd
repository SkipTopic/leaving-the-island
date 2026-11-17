extends Node
## T1 视觉验收 runner：截「我家室内」和「小镇家门口」两张图存到工作区。
## 运行: godot --path <项目> res://tests/shot_t1.tscn （非无头，需要窗口）
## 截完自动退出。intro_wake_done 预置位 → 室内跳过开场演出直接可看。

const OUT_DIR := "Zcode工作区域/00_思考过程/"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _frames(5)
	var base := ProjectSettings.globalize_path("res://").path_join("../" + OUT_DIR)

	# --- 图1：我家室内（跳过演出） ---
	Game.set_flag("intro_wake_done", true)
	var home: Node = load("res://scenes/town/home_interior.tscn").instantiate()
	get_tree().root.add_child(home)
	await _frames(30)
	_shot(base.path_join("T1_室内截图.png"))
	home.queue_free()
	await _frames(5)

	# --- 图2：小镇家门口（玩家站在 FromHome 落点） ---
	Game.pending_spawn = "FromHome"
	var town: Node = load("res://scenes/town/town.tscn").instantiate()
	get_tree().root.add_child(town)
	await _frames(30)
	_shot(base.path_join("T1_小镇门口截图.png"))
	town.queue_free()
	await _frames(3)
	get_tree().quit(0)


func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("已存: ", path, " (", img.get_width(), "x", img.get_height(), ")")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
