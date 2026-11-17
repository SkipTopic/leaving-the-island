extends Node
## 烘焙运行器：把建造脚本（town_build / worldmap_build）烤成纯场景文件。
## 运行: godot --headless --path <项目> res://tests/bake_town.tscn
## 注意：烘焙会覆盖 town.tscn / worldmap.tscn，编辑器里手动调过的布局会被覆盖。

const JOBS := [
	{"build": "res://scenes/town/home_interior_build.tscn", "out": "res://scenes/town/home_interior.tscn", "root": "res://scenes/town/home_root.gd"},
	{"build": "res://scenes/town/town_build.tscn", "out": "res://scenes/town/town.tscn", "root": "res://scenes/town/town_root.gd"},
	{"build": "res://scenes/town/town_build.tscn", "fn": "build_reveal", "out": "res://scenes/town/town_reveal.tscn", "root": "res://scenes/town/reveal_root.gd"},
	{"build": "res://scenes/world/worldmap_build.tscn", "out": "res://scenes/world/worldmap.tscn", "root": "res://scenes/world/world_root.gd"},
	{"build": "res://scenes/mountain/mountain_build.tscn", "out": "res://scenes/mountain/mountain_road.tscn", "root": "res://scenes/mountain/mountain_root.gd"},
	{"build": "res://scenes/office/office_build.tscn", "out": "res://scenes/office/office.tscn", "root": "res://scenes/office/office_root.gd"},
]


func _ready() -> void:
	_bake_all()


func _bake_all() -> void:
	await get_tree().process_frame
	var failed := false
	for job in JOBS:
		var err := await _bake_one(job)
		print(("BAKE OK  " if err == OK else "BAKE FAIL ") + job["out"])
		if err != OK:
			failed = true
	get_tree().quit(1 if failed else 0)


func _bake_one(job: Dictionary) -> Error:
	var packed_build: PackedScene = load(job["build"])
	if packed_build == null:
		push_error("找不到 " + job["build"])
		return ERR_CANT_OPEN
	var scene_root: Node2D = packed_build.instantiate()
	add_child(scene_root)
	if not scene_root.has_method(String(job.get("fn", "build"))):
		push_error(job["build"] + " 缺少 " + String(job.get("fn", "build")))
		return ERR_UNAVAILABLE
	scene_root.call(job.get("fn", "build"))
	await get_tree().process_frame

	# pack() 只收 owner=根 的节点；运行时添加的节点必须递归补 owner
	_set_owner_recursive(scene_root, scene_root)

	scene_root.name = String(job["out"].get_file().get_basename())
	scene_root.set_script(load(job["root"]))

	var packed := PackedScene.new()
	var err := packed.pack(scene_root)
	if err == OK:
		err = ResourceSaver.save(packed, job["out"])
	scene_root.queue_free()
	return err


func _set_owner_recursive(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		_set_owner_recursive(child, owner_root)
