extends SceneTree
## 图集接触表生成器：把图集按格切开、放大2倍、画红色网格线，方便挑格子。
## 用法: godot --headless --path <工程> --script <本文件> -- <图集路径> <格宽> <输出png>
## 例:   ... --script atlas_contact_sheet.gd -- "res://assets/tilesets/topdown_basic/stone_floor.png" 32 "D:/出图/stone_sheet.png"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var src_path: String = args[0] if args.size() > 0 else "res://assets/tilesets/topdown_basic/stone_floor.png"
	var cell: int = int(args[1]) if args.size() > 1 else 32
	var out_path: String = args[2] if args.size() > 2 else "atlas_sheet.png"

	var tex: Texture2D = load(src_path)
	var img: Image = tex.get_image()
	var cols := img.get_width() / cell
	var rows := img.get_height() / cell
	var scale := 2
	var out := Image.create(cols * cell * scale, rows * cell * scale, false, Image.FORMAT_RGBA8)

	for ry in rows:
		for rx in cols:
			var region := Rect2i(rx * cell, ry * cell, cell, cell)
			var piece := img.get_region(region)
			piece.resize(cell * scale, cell * scale, Image.INTERPOLATE_NEAREST)
			out.blit_rect(piece, Rect2i(0, 0, cell * scale, cell * scale), Vector2i(rx * cell * scale, ry * cell * scale))

	# 红色网格线
	for x in cols + 1:
		for y in out.get_height():
			out.set_pixel(mini(x * cell * scale, out.get_width() - 1), y, Color(1, 0, 0, 0.85))
	for y in rows + 1:
		for x in out.get_width():
			out.set_pixel(x, mini(y * cell * scale, out.get_height() - 1), Color(1, 0, 0, 0.85))

	out.save_png(out_path)
	print("接触表已存: %s (%dx%d 格, 每格%dpx)" % [out_path, cols, rows, cell * scale])
	quit(0)
