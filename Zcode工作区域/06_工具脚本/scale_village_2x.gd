extends SceneTree
## 工具：把 16px 村庄地块 2x 最近邻放大到 32px 基准。
## 运行: godot --headless --path <项目> --script <本文件>

const SRC_DIR := "res://assets/tilesets/village_topdown/"
const OUT_DIR := "res://assets/tilesets/village_topdown_2x/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var d := DirAccess.open(SRC_DIR)
	if d == null:
		push_error("打不开源目录")
		quit(1)
		return
	var count := 0
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if f.ends_with(".png"):
			var img := Image.load_from_file(ProjectSettings.globalize_path(SRC_DIR + f))
			if img != null:
				var big := img.duplicate()
				big.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
				var out_path := OUT_DIR + f.get_basename() + "_2x.png"
				big.save_png(ProjectSettings.globalize_path(out_path))
				count += 1
				print("2x: ", f, " -> ", out_path)
		f = d.get_next()
	print("完成，共 ", count, " 张")
	quit(0)
