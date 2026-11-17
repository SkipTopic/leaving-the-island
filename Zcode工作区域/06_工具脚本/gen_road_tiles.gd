extends SceneTree
## 现代公路瓦片生成器：深褐柏油/中央白虚线/两侧白实线 + 火山观测站大门贴图。
## 用户要求：村庄=古代土路，山道=现代高速（深褐+条状标线），风格与像素管线统一。
## 用法: godot --headless --path <工程> --script <本文件>
## 产物: assets/tilesets/generated/road_asphalt.png 等 4 块 32px + road_gate.png 160x56

const OUT := "res://assets/tilesets/generated/"
const CELL := 32

# 柏油基色（深褐，比土路暗得多）与标线米白
const ASPHALT := Color(0.30, 0.26, 0.22)
const LINE := Color(0.85, 0.82, 0.72)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save(_asphalt(false, false, false), "road_asphalt.png")
	_save(_asphalt(true, false, false), "road_dash.png")     # 中央白虚线段
	_save(_asphalt(false, true, false), "road_edge_l.png")   # 左侧白实线
	_save(_asphalt(false, false, true), "road_edge_r.png")   # 右侧白实线
	_save(_gate(), "road_gate.png")
	print("公路瓦片生成完毕 → ", OUT)
	quit(0)


## 柏油砖：基底噪点 ±6%；dash=中央竖向虚线段(上下各留6px)；edge_l/r=侧边白实线
func _asphalt(dash: bool, edge_l: bool, edge_r: bool) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261104
	var img := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	for y in CELL:
		for x in CELL:
			var f := 1.0 + rng.randf_range(-0.06, 0.06)
			img.set_pixel(x, y, Color(ASPHALT.r * f, ASPHALT.g * f, ASPHALT.b * f))
	if dash:
		for y in range(6, CELL - 6):
			for x in range(15, 17):
				img.set_pixel(x, y, LINE)
	if edge_l:
		for y in CELL:
			for x in range(2, 4):
				img.set_pixel(x, y, LINE)
	if edge_r:
		for y in CELL:
			for x in range(28, 30):
				img.set_pixel(x, y, LINE)
	return img


## 观测站大门（160x56，底边=排序原点）：两根门柱 + 黄黑警示横梁 + 中央密码键盘
func _gate() -> Image:
	var img := Image.create(160, 56, false, Image.FORMAT_RGBA8)
	var pillar := Color(0.22, 0.24, 0.27)
	var beam := Color(0.26, 0.28, 0.30)
	# 门柱 x 4..20 / 140..156, y 0..52
	for y in range(4, 52):
		for x in range(4, 21):
			img.set_pixel(x, y, pillar)
		for x in range(139, 156):
			img.set_pixel(x, y, pillar)
	# 横梁 y 6..20
	for y in range(6, 21):
		for x in range(4, 156):
			img.set_pixel(x, y, beam)
	# 黄黑警示条（横梁中带，每 8px 交替）
	for y in range(10, 17):
		for x in range(4, 156):
			if int(x / 8.0) % 2 == 0:
				img.set_pixel(x, y, Color(0.78, 0.64, 0.22))
			else:
				img.set_pixel(x, y, Color(0.08, 0.08, 0.08))
	# 中央密码键盘盒（挂在横梁下）
	for y in range(20, 46):
		for x in range(66, 94):
			img.set_pixel(x, y, Color(0.16, 0.17, 0.19))
	for y in range(24, 40):
		for x in range(70, 90):
			var f := 1.0 if (int(x / 5.0) + int(y / 4.0)) % 2 == 0 else 0.7
			img.set_pixel(x, y, Color(0.10 * f + 0.05, 0.32 * f, 0.14 * f))
	# 键盘指示灯（绿）
	for y in range(21, 24):
		for x in range(76, 84):
			img.set_pixel(x, y, Color(0.35, 0.9, 0.4))
	return img


func _save(img: Image, fname: String) -> void:
	var err := img.save_png(OUT + fname)
	print("  %s → %s" % [fname, "OK" if err == OK else error_string(err)])
