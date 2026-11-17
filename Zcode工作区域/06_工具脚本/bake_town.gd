extends SceneTree
## 工具：把 town_build.tscn（建造脚本）烘焙成 town.tscn（纯场景文件）。
## 烘焙后场景里的一切（树/房/井/NPC/碰撞/TileMap地块）都是可编辑节点。
## 运行: godot --headless --path <项目> --script <本文件>
##
## 注意：烘焙会覆盖 town.tscn。如果你在编辑器里手动调整过 town.tscn，
## 重烘焙会覆盖掉这些调整——要么先备份，要么把改动同步回 town_build.gd。


func _init() -> void:
	var err := _bake()
	print("BAKE OK" if err == OK else "BAKE FAIL (%s)" % error_string(err))
	quit(err)


func _bake() -> Error:
	var packed_build: PackedScene = load("res://scenes/town/town_build.tscn")
	if packed_build == null:
		push_error("找不到 town_build.tscn")
		return ERR_CANT_OPEN
	var town: Node2D = packed_build.instantiate()
	root.add_child(town)
	if not town.has_method("build"):
		push_error("town_build.gd 缺少 build()")
		return ERR_UNAVAILABLE
	town.build()

	# 换上运行时根脚本，定名
	town.name = "Town"
	town.set_script(load("res://scenes/town/town_root.gd"))

	var packed := PackedScene.new()
	var err := packed.pack(town)
	if err != OK:
		push_error("pack 失败")
		return err
	err = ResourceSaver.save(packed, "res://scenes/town/town.tscn")
	town.queue_free()
	return err
