extends SceneTree
## 工具：把村庄包的零散装饰小图（2x 后各 32x32）横向拼成条状图集，
## 方便 Town TileSet 用单一 atlas source 管理。
## 运行: godot --headless --path <项目> --script <本文件>

const SRC := "res://assets/tilesets/village_topdown_2x/"
const OUT := "res://assets/tilesets/stitched/"

const JOBS := {
	"grass_details.png": [
		"GRASS DETAIL 1 - DAY_2x.png",
		"GRASS DETAIL 2 - DAY_2x.png",
		"GRASS DETAIL 3 - DAY_2x.png",
		"GRASS DETAIL 4 - DAY_2x.png",
		"GRASS DETAIL 5 - DAY_2x.png",
		"GRASS DETAIL 6 - DAY_2x.png",
	],
	"ground_details.png": [
		"GROUND DETAIL 1 - DAY_2x.png",
		"GROUND DETAIL 2 - DAY_2x.png",
		"GROUND DETAIL 3 - DAY_2x.png",
		"GROUND DETAIL 4 - DAY_2x.png",
		"GROUND DETAIL 5 - DAY_2x.png",
	],
	"water_details.png": [
		"WATER DETAIL 1 - DAY_2x.png",
		"WATER DETAIL 2 - DAY_2x.png",
		"WATER DETAIL 3 - DAY_2x.png",
		"WATER DETAIL 4 - DAY_2x.png",
		"WATER DETAIL 5 - DAY_2x.png",
	],
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for out_name in JOBS:
		var files: Array = JOBS[out_name]
		var imgs: Array = []
		for f in files:
			var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + f))
			if img == null:
				push_warning("缺图，跳过: " + f)
				continue
			if img.get_width() != 32 or img.get_height() != 32:
				push_warning("尺寸不是32x32，跳过: %s (%dx%d)" % [f, img.get_width(), img.get_height()])
				continue
			if img.get_format() != Image.FORMAT_RGBA8:
				img.convert(Image.FORMAT_RGBA8)
			imgs.append(img)
		if imgs.is_empty():
			continue
		var atlas := Image.create(32 * imgs.size(), 32, false, Image.FORMAT_RGBA8)
		for i in imgs.size():
			atlas.blit_rect(imgs[i], Rect2i(0, 0, 32, 32), Vector2i(32 * i, 0))
		atlas.save_png(ProjectSettings.globalize_path(OUT + out_name))
		print("拼接: ", out_name, " (", imgs.size(), " 格)")
	quit(0)
