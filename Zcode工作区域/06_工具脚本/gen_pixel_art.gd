extends SceneTree
## 工具：像素画生成器 —— 素材包里没有的图我自己画。
## 用 ASCII 字符画定义像素图 + 调色板，生成 PNG。
## 运行: godot --headless --path <项目> --script <本文件>

const OUT_DIR := "res://assets/sprites/custom/"

# ---------- 调色板 ----------
const PAL := {
	".": null,                          # 透明
	"O": Color("3a2a1e"),               # 深棕描边
	"B": Color("8a5a33"),               # 野猪身体
	"D": Color("66401f"),               # 身体暗部
	"L": Color("c49a6c"),               # 肚皮亮部
	"T": Color("f2ead6"),               # 獠牙/亮白
	"E": Color("141210"),               # 眼
	"N": Color("2a1c12"),               # 鼻头
	"W": Color("9a9a92"),               # 石子灰
	"w": Color("c2c2ba"),               # 石子亮灰
	"M": Color("6e4f2f"),               # 木牌木色
	"m": Color("8f6b40"),               # 木牌浅木
	"K": Color("4a3421"),               # 深木(箱)
	"k": Color("75552f"),               # 浅木(箱)
	"Y": Color("d9b25f"),               # 草杆黄
	"G": Color("5d7a3a"),               # 扫帚草绿
	"g": Color("47602c"),               # 扫帚草深
	"S": Color("b8b2a6"),               # 旧木柄
	"R": Color("7d2f21"),               # 旧漆红(火柴盒条纹)
	"C": Color("d9c9a8"),               # 米色(火柴盒标签)
	"Q": Color("9a4a33"),               # 被子红棕(床)
	"q": Color("7a3526"),               # 被子暗部褶皱
	"U": Color("a8c8d8"),               # 窗玻璃亮
	"u": Color("7ba7c0"),               # 窗玻璃暗
	"P": Color("b07f3e"),               # 油灯铜座
	"p": Color("8a5f28"),               # 油灯铜暗部
	"H": Color("46525e"),               # 远船剪影深
	"h": Color("5a6874"),               # 远船剪影浅
}

# ---------- 野猪 (26x16, 朝左) ----------
const BOAR_1 := """
..........................
......OOOO................
.....OBBBBO...............
....OBBBBBBOO.............
...OBBBBBBBBOO............
..OBBBBBBBBBBOO...........
..OBLLLLLBBBBOOO..........
.OBLLLLLLBBBOOBOO.........
.OBLLLLLLBBBOBEBBOO.......
.OBLLLLLLBBBBBBBBBBOO.....
..OBLLLLBBBBBBBTBNBBO.....
..OBBLLBBBBBBBOBTTNBO.....
...OBBBBBBBBBBOOOOO.......
....OBO..OBO..OBO.........
....OBO..OBO..OBO.........
.....OO...OO...OO.........
"""

const BOAR_2 := """
..........................
......OOOO................
.....OBBBBO...............
....OBBBBBBOO.............
...OBBBBBBBBOO............
..OBBBBBBBBBBOO...........
..OBLLLLLBBBBOOO..........
.OBLLLLLLBBBOOBOO.........
.OBLLLLLLBBBOBEBBOO.......
.OBLLLLLLBBBBBBBBBBOO.....
..OBLLLLBBBBBBBTBNBBO.....
..OBBLLBBBBBBBOBTTNBO.....
...OBBBBBBBBBBOOOOO.......
...OBO...OBO...OBO........
...OBO...OBO...OBO........
....OO....OO....OO........
"""

const BOAR_CHARGE := """
..........................
....OOOOO.................
...OBBBBBOO...............
..OBBBBBBBBO..............
..OBBBBBBBBBOO............
.OBLLLLLBBBBBOO...........
.OBLLLLLLBBBBOO...........
.OBLLLLLLBBBBEBOO.........
..OBLLLLBBBBBBBBBOO.......
..OBLLBBBBBBBBTBNBBO......
...OBBBBBBBBBBBTTNBO......
....OBO..OBO..OOOOO.......
....OBO..OBO..............
.....OO...OO..............
..........................
..........................
"""

# ---------- 木箱 (12x12, 陈婆怀里) ----------
const CRATE := """
OOOOOOOOOOOO
OkkkkkkkkkKO
OkKkkkkkkkKO
OkkkkKKkkkKO
OkkkKKKKkkKO
OkkKKKKKKkKO
OkkkKKKKkkKO
OkkkkKKkkkKO
OkKkkkkkkkKO
OkkkkkkkkkKO
OKKKKKKKKKKO
OOOOOOOOOOOO
"""

# ---------- 扫帚 (10x22) ----------
const BROOM := """
.......SS.
.......SS.
......SS..
......SS..
.....SS...
.....SS...
....SS....
....SS....
...SS.....
...sS.....
..OGGO....
.OGGGGO...
OGgGGgGO..
OGgGGgGO..
.OGgGgO...
.OGgGgO...
..OGGO....
..OGGO....
...OO.....
..........
"""

# ---------- 石子 (8x8) ----------
const STONE := """
..OOOO..
.OwWWwO.
OwWWWWWw
OWWWWWWw
OWWWWWWO
OWWwWWWo
.OwWWwO.
..OOOO..
"""

# ---------- 木牌 (18x20, 素面木板+木纹) ----------
const SIGN := """
.OOOOOOOOOOOOOOOO.
.OKKKKKKKKKKKKKKO.
.OKmmmmmmmmmmmmKO.
.OKmKmmmmmmmmKKO..
.OKmmmmmmKKmmmKO..
.OKmKKmmmmmmmmKO..
.OKmmmmmmmmKKmKO..
.OKmmmKKmmmmmmKO..
.OKmmmmmmmmmmmKO..
.OKKmmmmKKmmmmKO..
.OKmmmmmmmmmmKKO..
.OKKKKKKKKKKKKKKO.
..OOOOOOOOOOOOOO..
.......OSO........
.......OSO........
.......OSO........
.......OSO........
......OOOSOOO.....
"""

# ---------- 水井 (24x28, 存档点) ----------
const WELL := """
...........OO...........
.........OOKKOO.........
.......OOKmmmmKOO.......
.....OOKmmmmmmmKOO......
....OKmmmmmmmmmmmKO.....
...OKmmmmmmmmmmmmmKO....
...OKKKKKKKKKKKKKKKO....
...OS..............SO...
...OS..............SO...
...OS..............SO...
...OS..............SO...
...OS..............SO...
...OS..............SO...
...OS..............SO...
...OS..............SO...
..OOOO..........OOOO....
..OwWWO........OwWWO....
.OwWWWWO......OwWWWWO...
.OWWWWWWO....OWWWWWWO...
.OWWwwWWWO..OWWWwwWWO...
.OWW....WWO.OWW....WWO..
.OWW....WWOOOWW....WWO..
.OWW....WNNNNNW....WWO..
.OWW....WNNNNNW....WWO..
.OWW....WWWWWWW....WWO..
..OWW..WWWWWWWW..WWO....
...OOWWWWWWWWWWWWWOO....
.....OOOOOOOOOOOOOO.....
"""


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_save("boar_walk_1", BOAR_1)
	_save("boar_walk_2", BOAR_2)
	_save("boar_charge", BOAR_CHARGE)
	_save("crate", CRATE)
	_save("broom", BROOM)
	_save("stone", STONE)
	_save("sign_north", SIGN)
	_save("well", WELL)
	_save("biscuit", BISCUIT)
	_save("matchbox", MATCHBOX)
	_save("book", BOOK)
	_save("map_item", MAP_ITEM)
	_save("bird", BIRD)
	# --- T1 开场：我家室内家具 ---
	_save("bed", BED)
	_save("table", TABLE)
	_save("cabinet", CABINET)
	_save("stool", STOOL)
	_save("window", WINDOW)
	_save("lamp", LAMP)
	_save("door_mat", DOOR_MAT)
	# --- 内容补完：会堂钢琴 / 六叔渔网 / 乐谱 / 结局二船影 ---
	_save("piano", PIANO)
	_save("net", NET)
	_save("sheet_music", SHEET)
	_save("ship", SHIP)
	# --- 序章爆发：黑雪片 / 灰烬点 / 隧道抖动光斑 ---
	_save("ash_flake", ASH_FLAKE)
	_save("ash_speck", ASH_SPECK)
	_gen_light_spot()
	_gen_slash()
	print("像素画生成完毕")
	quit(0)


func _save(name: String, art: String) -> void:
	var lines := _parse(art)
	var h := lines.size()
	var w := 0
	for l in lines:
		w = max(w, l.length())
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var line: String = lines[y]
		for x in w:
			var ch: String = line[x] if x < line.length() else "."
			if PAL.has(ch) and PAL[ch] != null:
				img.set_pixel(x, y, PAL[ch])
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + name + ".png"))
	print("生成: ", name, ".png (", w, "x", h, ")")


# ---------- 压缩饼干 (16x10) ----------
const BISCUIT := """
.OOOOOOOOOOOOOO.
.OMMMMMMMMMMMMO.
.OMmmMMmmMMmmMO.
.OMMMMMMMMMMMMO.
.OMmmMMmmMMmmMO.
.OMMMMMMMMMMMMO.
.OMmmMMmmMMmmMO.
.OMMMMMMMMMMMMO.
.OMMMMMMMMMMMMO.
.OOOOOOOOOOOOOO.
"""

# ---------- 火柴盒 (14x16) ----------
const MATCHBOX := """
.OOOOOOOOOOOO.
.OMMMMMMMMMMO.
.OMRRRRRRRRMO.
.OMRCCCCCCRMo.
.OMRCCCCCCRMo.
.OMRRRRRRRRMo.
.OMMMMMMMMMMo.
.OMmmmmmmmmMo.
.OMMMMMMMMMMo.
.OMmmmmmmmmMo.
.OMMMMMMMMMMo.
.OMmmmmmmmmMo.
.OMMMMMMMMMMo.
.OMMMMMMMMMMo.
.OMMMMMMMMMMO.
.OOOOOOOOOOOO.
"""

# ---------- 值班日志本 (14x16, 蓝皮) ----------
const BOOK := """
..OOOOOOOOOO..
.OBBBBBBBBBBO.
.OBCCCCCCCCBO.
.OBCBBBBBBCBO.
.OBCBWCCCCBO..
.OBCBWCCCCBOO.
.OBCBBBBBBCBO.
.OBCCCCCCCCBO.
.OBCCCCCCCCBO.
.OBCBBBBBBCBO.
.OBCWWCCCCCBO.
.OBCCCCCCCCBO.
.OBCCCCCCCCBO.
.OBBBBBBBBBBO.
.OBBBBBBBBBBO.
..OOOOOOOOOO..
"""

# ---------- 折叠地图 (16x12) ----------
const MAP_ITEM := """
.OOOOOOOOOOOOOO.
.OMMMCCCCCCCMMO.
.OMMCCGGGGGCCMO.
.OMCCGGGWWGGCMO.
.OMCCGGGWWGGCMO.
.OMMCCGGGGGCCMO.
.OMMCCCCRCCCCMO.
.OMMMCCCRRCCCMO.
.OMMMMCCCCCCCCO.
.OMMCCCCCCCCCMO.
.OMMCCCCCCCCMO..
.OOOOOOOOOOOOOO.
"""

# ---------- 低飞鸟 (12x10, 朝左) ----------
const BIRD := """
....OOOO....
...OWWWWO...
..OWWWWWWO..
.OWWWETWWWO.
OWWWWWWWWWWO
.OWTWWWWWOO.
..OOWWWWOO..
....OOOO....
....OWWO....
.....OO.....
"""

# ---------- 单人床 (32x62, 竖放·床头朝上) ----------
const BED := """
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKmKmmmmKKmmmmmmmmKKmmmmmmmmKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.OTTTTTTTTTTTTTTTTTTTTTTTTTTTTO.
.OTTTTTTTTTTTTTTTTTTTTTTTTTTTTO.
.OTTTTTOOTTTTTTTTTTTTTOOTTTTTTO.
.OTTTTTOOTTTTTTTTTTTTTOOTTTTTTO.
.OTTTTTTTTTTTTTTTTTTTTTTTTTTTTO.
.OTTTTTTTTTTTTTTTTTTTTTTTTTTTTO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.ODDDDDDDDDDDDDDDDDDDDDDDDDDDDO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQqqqqqqqqqqqqqqqqqqqqqqqqqqQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQqqqqqqqqqqqqqqqqqqqqqqqqqqQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQqqqqqqqqqqqqqqqqqqqqqqqqqqQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQqqqqqqqqqqqqqqqqqqqqqqqqqqQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQqqqqqqqqqqqqqqqqqqqqqqqqqqQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQqqqqqqqqqqqqqqqqqqqqqqqqqqQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQqqqqqqqqqqqqqqqqqqqqqqqqqqQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OQQQQQQQQQQQQQQQQQQQQQQQQQQQQO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.ODDDDDDDDDDDDDDDDDDDDDDDDDDDDO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.OKkkkkkkkkkkkkkkkkkkkkkkkkkkKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
"""

# ---------- 木桌 (48x24, 桌面拼板+四腿) ----------
const TABLE := """
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKmmKKmmmmmmmKKKmmmmmmmmKKmmmmmmmmKKKmmmmmmmKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKmmKKmmmmmmmKKKmmmmmmmmKKmmmmmmmmKKKmmmmmmmKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKmmKKmmmmmmmKKKmmmmmmmmKKmmmmmmmmKKKmmmmmmmKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKmmKKmmmmmmmKKKmmmmmmmmKKmmmmmmmmKKKmmmmmmmKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
....OKKO................................OKKO....
....OKKO................................OKKO....
....OSSO................................OSSO....
....OOOO................................OOOO....
"""

# ---------- 立柜 (32x41, 双门+铜把手) ----------
const CABINET := """
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKKKmmmmmmmmmmmmmmmmmmmmmmKKKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmTYKKTYmmmmmmmmmmmKO.
.OKmmmmmmmmmTYKKTYmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKmmmmmmmmmmmmKKmmmmmmmmmmmmKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKmmmmmmmmmmmmmmmmmmmmmmmmmmKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
"""

# ---------- 圆凳 (16x8) ----------
const STOOL := """
....OOOOOOOO....
..OOkkkkkkkkOO..
.OkmmmmmmmmmmkO.
.OKKKKKKKKKKKKO.
...OSSSSSSSSO...
..OSO......OSO..
..OSO......OSO..
...OO......OO...
"""

# ---------- 木框窗 (32x30, 挂在墙上) ----------
const WINDOW := """
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKUUUUUUUUUUKKUUUUUUUUUUUUUUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKUUUUUUUUUUKKUUUUUUUuuuuUuUKO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
"""

# ---------- 油灯 (12x11, 放桌上) ----------
const LAMP := """
....OYYO....
...OYTTYO...
...OYTTYO...
....OYYO....
....OPPO....
...OPPPPO...
..OPppppPO..
..OPppppPO..
..OPPPPPPO..
...OppppO...
....OOOO....
"""

# ---------- 门口地垫 (32x8, 木条拼的擦脚垫) ----------
const DOOR_MAT := """
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
.OkkkkkkkkkkkkkkkkkkkkkkkkkkkkO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OkkkkkkkkkkkkkkkkkkkkkkkkkkkkO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OkkkkkkkkkkkkkkkkkkkkkkkkkkkkO.
.OKKKKKKKKKKKKKKKKKKKKKKKKKKKKO.
.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.
"""

# ---------- 立式钢琴 (48x30, 会堂门口/结局一) ----------
const PIANO := """
......OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO......
......KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK......
......KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK......
......KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK......
......KkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KmmmmmmmmmmKKkkkkkkkkkkkkkkkkkkkkkKK......
......KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK......
..OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO..
......TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT......
......TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT......
......TTTETTTETTTETTTETTTETTTETTTETTTETTTE......
......TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT......
......TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT......
......TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT......
..OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO..
....OKKO................................OKKO....
....OOOO................................OOOO....
"""

# ---------- 渔网 (16x11, 六叔手持) ----------
const NET := """
....OOOOOOOO....
...O..O..O..O...
..O.O.O.O.O.O...
.O..O..O..O..O..
..O.O.O.O.O.O...
...O..O..O..O...
..O.O.O.O.O.O...
.O..O..O..O..O..
..O.O.O.O.O.O...
...O..O..O..O...
....OOOOOOOO....
"""

# ---------- 乐谱 (12x10, 阿蓝手边) ----------
const SHEET := """
.OOOOOOOOOO.
.OCCCCCCCCO.
.OCKKKKKKKO.
.OCCECECCCO.
.OCKKKKKKKO.
.OCCCECCCCO.
.OCKKKKKKKO.
.OCCCCCCCCO.
.OCCCCCCCCO.
.OOOOOOOOOO.
"""

# ---------- 远处大船剪影 (80x26, 结局二《回信》海平线) ----------
const SHIP := """
................................................................................
................................................................................
..........................................................HHHHHH................
..........................................................HHHHHH................
..........................................................HHHHHH................
..........................................................HHHHHH................
..........................................................HHHHHH................
......................................................hHHHHHHh..................
......................................................hHHHHHHHHh................
......................................................hHHHHHHHHh................
......................................................hHHHHHHHHh................
......................................................hHHHHHHHHh................
......................................................hHHHHHHHHh................
......................................................hHHHHHHHHh................
........................................hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh......
........................................hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh......
........................................hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh......
........................................hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh......
........................................hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh......
..HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH..
..HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH..
..HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH..
..HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH..
..HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH..
....HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH....
................................................................................
"""

# ---------- 黑雪片 (10x7, 粒子贴图·白色便于运行时调色) ----------
const ASH_FLAKE := """
...OWWW...
..OWWWWW..
.OWWWWWWW.
.OWWWWWWW.
..OWWWWWo.
...OWWo...
....O.....
"""

# ---------- 灰烬点 (5x5, 粒子贴图·白色便于运行时调色) ----------
const ASH_SPECK := """
.OWWO.
OWWWWO
OWWWWO
.OWWO.
..O...
"""


## 隧道手电光斑：数学生成的径向渐变（128x128），边缘用 2x2 Bayer 抖动
## 量化成像素阶梯——像素风的光就该有"颗粒感"，而不是纯净的高斯糊。
func _gen_light_spot() -> void:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var bayer := [[0, 2], [3, 1]]  # 2x2 抖动矩阵
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - size / 2.0, y + 0.5 - size / 2.0).length() / (size / 2.0)
			if d >= 1.0:
				continue
			var a := pow(1.0 - d, 1.7)  # 平方衰减：中心亮、边缘收得快
			# 量化到 5 档亮度，抖动阈值打散阶梯边
			var th := float(bayer[y % 2][x % 2]) / 4.0 - 0.375
			var levels := 5
			var q := clampi(int((a + th * 0.22) * levels), 0, levels - 1)
			var bright := float(q + 1) / levels
			var col := Color(1.0, 0.96, 0.86, bright)
			img.set_pixel(x, y, col)
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + "light_spot.png"))
	print("生成: light_spot.png (128x128 抖动光斑)")


## 挥砍弧光：数学生成的上凸月牙（24x24），由 Pivot 旋转指向攻击方向。
func _gen_slash() -> void:
	var size := 24
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(12, 17)
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if y <= 12 and d >= 9.0 and d <= 13.5:
				var edge := 1.0
				if d > 12.5:
					edge = 1.0 - (d - 12.5) / 1.0
				elif d < 9.8:
					edge = (d - 9.0) / 0.8
				var a: float = clampf(edge, 0.0, 1.0)
				var col := Color(0.96, 0.94, 0.82, a) if d < 11.8 else Color(0.78, 0.74, 0.6, a * 0.8)
				img.set_pixel(x, y, col)
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + "slash.png"))
	print("生成: slash.png (24x24)")


func _parse(art: String) -> Array:
	var lines := []
	for raw in art.split("\n"):
		if raw.strip_edges() == "" and lines.is_empty():
			continue  # 跳过开头的空行
		lines.append(raw)
	while lines.size() > 0 and lines[lines.size() - 1].strip_edges() == "":
		lines.pop_back()  # 跳过结尾空行
	return lines
