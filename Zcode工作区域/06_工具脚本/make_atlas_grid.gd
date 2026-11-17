extends SceneTree
## 工具：给 Pipoya 世界图集叠加 32px 网格与坐标标注，存到工作区（不进工程）。
## 运行: godot --headless --path <项目> --script <本文件>

const SRC := "res://assets/tilesets/pipoya_world_32/pipo-map001.png"
const OUT := "D:/我的godot项目/最后离开的我/Zcode工作区域/00_思考过程/atlas_grid.png"


func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var font_col := Color(1, 0.2, 0.2)
	var grid_col := Color(1, 1, 0, 0.55)
	for x in range(0, w + 1, 32):
		for y in h:
			img.set_pixel(mini(x, w - 1), y, grid_col)
	for y in range(0, h + 1, 32):
		for x in w:
			img.set_pixel(x, mini(y, h - 1), grid_col)
	# 列号/行号（每格中心画个小十字+跳过标注文字，字号太小的字体不可用，用十字定位）
	for cx in range(0, w, 32):
		var mid := cx + 16
		for k in range(14, 19):
			img.set_pixel(mini(mid, w - 1), mini(k, h - 1), font_col)
	for cy in range(0, h, 32):
		var midy := cy + 16
		for k in range(6, 11):
			img.set_pixel(mini(k, w - 1), mini(midy, h - 1), font_col)
	var dir := OUT.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(OUT)
	print("saved: ", OUT, " ", w, "x", h, " (格=32px, 黄线网格, 红十字=格中心)")
	quit(0)
