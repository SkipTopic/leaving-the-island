extends SceneTree
## 草地变体生成器：从现有草砖程序化生成 3 个色调变体（深草/浅草/杂色草皮），
## 给 town/worldmap 的噪声散布用。固定种子，可重复生成。
## 用法: godot --headless --path <工程> --script <本文件>
## 产物: assets/tilesets/generated/grass_dark.png / grass_light.png / grass_patch.png

const SRC_TEX := "res://assets/tilesets/village_topdown_2x/GRASS TILE - DAY_2x.png"
const OUT_DIR := "res://assets/tilesets/generated/"
const CELL := 32  # 图集里草砖用的区域大小（tileset 里 texture_region_size=32）

var rng := RandomNumberGenerator.new()


func _init() -> void:
	var tex: Texture2D = load(SRC_TEX)
	var img: Image = tex.get_image()
	# 草砖实际使用的是图集左上 32×32（tileset 只建了 0:0 一格）
	var base := img.get_region(Rect2i(0, 0, CELL, CELL))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_save(_tone(base, 0.90, 0.08, 0), "grass_dark.png")    # 深草：整体压暗+少量噪点
	_save(_tone(base, 1.08, 0.08, 0), "grass_light.png")   # 浅草：整体提亮+少量噪点
	_save(_blotch(base), "grass_patch.png")                # 杂色草皮：基底+深色斑块
	print("草地变体生成完毕 → ", OUT_DIR)
	quit(0)


## 色调缩放 + 像素噪点（speckle_prob 比例的像素随机明暗 ±amp）
func _tone(src: Image, mul: float, amp: float, _seed_unused: int) -> Image:
	rng.seed = 20261102
	var out := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			var f := mul
			if rng.randf() < 0.10:
				f += rng.randf_range(-amp, amp)
			out.set_pixel(x, y, Color(
				clampf(c.r * f, 0.0, 1.0),
				clampf(c.g * f, 0.0, 1.0),
				clampf(c.b * f, 0.0, 1.0), c.a))
	return out


## 杂色草皮：基底微暗 + 若干深色斑块（2×3 椭圆），像草皮的自然色块
func _blotch(src: Image) -> Image:
	rng.seed = 20261103
	var out := _tone(src, 0.96, 0.06, 0)
	for i in 7:
		var cx := rng.randi_range(2, CELL - 3)
		var cy := rng.randi_range(2, CELL - 3)
		var rw := rng.randi_range(2, 4)
		var rh := rng.randi_range(1, 3)
		for y in range(cy - rh, cy + rh + 1):
			for x in range(cx - rw, cx + rw + 1):
				if x < 0 or y < 0 or x >= CELL or y >= CELL:
					continue
				var dx := float(x - cx) / rw
				var dy := float(y - cy) / rh
				if dx * dx + dy * dy <= 1.0 and rng.randf() < 0.8:
					var c := out.get_pixel(x, y)
					out.set_pixel(x, y, Color(c.r * 0.84, c.g * 0.84, c.b * 0.84, c.a))
	return out


func _save(img: Image, fname: String) -> void:
	var err := img.save_png(OUT_DIR + fname)
	print("  %s → %s" % [fname, "OK" if err == OK else error_string(err)])
