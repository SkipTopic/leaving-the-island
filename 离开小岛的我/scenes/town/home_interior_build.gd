extends Node2D
## 我家室内「建造脚本」—— 只被 bake 工具调用一次，把内容物实例化。
## 烘焙完成后 home_interior.tscn 就是纯场景文件，本脚本不再参与运行。
## 石头房子室内：石砖墙 + 石地板（Pixel Art Top Down - Basic 包）+ 自绘家具。
## 改布局/改摆放 → 改这里后重跑 bake（会覆盖 home_interior.tscn）。

const TILE := 32
const MAP_W := 16   # 512px：16×10 小屋（用户拍板）；配合相机2倍变焦（视野320×180），镜头可平移
const MAP_H := 10   # 320px

# —— 石地板（stone_floor.png 8x8 图集）噪声拼纹 ——
# 大石板四块象限：按 (x%2, y%2) 对位才能拼出完整大石板（之前只贴四分之一块，图案是碎的）
const SLAB_TL := Vector2i(0, 0)
const SLAB_TR := Vector2i(1, 0)
const SLAB_BL := Vector2i(0, 1)
const SLAB_BR := Vector2i(1, 1)
# 变体格：素面磨损砖×2 / 内嵌方砖 / 铆钉铁板
const FLOOR_PLAIN := Vector2i(0, 4)
const FLOOR_PLAIN2 := Vector2i(1, 4)
const FLOOR_SQUARE := Vector2i(1, 6)
const FLOOR_RIVET := Vector2i(5, 1)
## 磨损区噪声频率：越小磨损区块越大
const FLOOR_NOISE_FREQ := 0.16
## 磨损阈值：噪声低于此值的区域铺素面砖（成团分布，不撒芝麻）
const FLOOR_WORN_TH := -0.30
## 内嵌方砖出现概率（非磨损区逐格判定）
const FLOOR_SQUARE_P := 0.035
## 铆钉铁板出现概率
const FLOOR_RIVET_P := 0.04
# 墙图集（wall_tiles.png）里的横墙带：上排=墙帽，下排=墙面，各4格可循环
const WALL_CAPS := [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6)]
const WALL_FACES := [Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7)]

var rng := RandomNumberGenerator.new()

@onready var ground: TileMapLayer = $Ground
@onready var world: Node2D = $World
@onready var furniture: Node2D = $World/Furniture


## 由 bake_town.gd 调用；幂等（先清空再建）。
func build() -> void:
	rng.seed = 20261101
	for c in [furniture]:
		for child in c.get_children():
			child.queue_free()
	ground.tile_set = _make_tileset()
	_build_floor_and_walls()
	_place_furniture()
	_place_player()
	_place_walls_and_door()
	_warm_tint()


# ---------- 地块 ----------

## 代码构建 TileSet：0=石地板 1=石砖墙（32px 图集，无物理，物理墙单独摆）
func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var floor_src := TileSetAtlasSource.new()
	floor_src.texture = load("res://assets/tilesets/topdown_basic/stone_floor.png")
	floor_src.texture_region_size = Vector2i(TILE, TILE)
	for c in [SLAB_TL, SLAB_TR, SLAB_BL, SLAB_BR, FLOOR_PLAIN, FLOOR_PLAIN2, FLOOR_SQUARE, FLOOR_RIVET]:
		floor_src.create_tile(c)
	ts.add_source(floor_src, 0)
	var wall_src := TileSetAtlasSource.new()
	wall_src.texture = load("res://assets/tilesets/topdown_basic/wall_tiles.png")
	wall_src.texture_region_size = Vector2i(TILE, TILE)
	for c in WALL_CAPS + WALL_FACES:
		wall_src.create_tile(c)
	ts.add_source(wall_src, 1)
	return ts


func _build_floor_and_walls() -> void:
	# 磨损区噪声场：固定种子，每次烘焙一致
	var fn := FastNoiseLite.new()
	fn.seed = 20261101
	fn.noise_type = FastNoiseLite.TYPE_PERLIN
	fn.frequency = FLOOR_NOISE_FREQ
	for y in MAP_H:
		for x in MAP_W:
			if y < 2:
				# 前两行=石砖墙：第0行墙帽、第1行墙面，4格循环拼横墙
				ground.set_cell(Vector2i(x, y), 1, WALL_CAPS[x % 4])
				if y == 1:
					ground.set_cell(Vector2i(x, y), 1, WALL_FACES[x % 4])
			else:
				# 地板：大石板2×2打底，磨损区/方砖/铆钉板噪声成团点缀
				var v: Vector2i
				var n := fn.get_noise_2d(x, y)
				if n < FLOOR_WORN_TH:
					v = FLOOR_PLAIN if rng.randf() < 0.5 else FLOOR_PLAIN2
				elif rng.randf() < FLOOR_SQUARE_P:
					v = FLOOR_SQUARE
				elif rng.randf() < FLOOR_RIVET_P:
					v = FLOOR_RIVET
				else:
					v = [SLAB_TL, SLAB_TR, SLAB_BL, SLAB_BR][(x % 2) + 2 * (y % 2)]
				ground.set_cell(Vector2i(x, y), 0, v)


# ---------- 家具（全部自绘，风格对齐 32px） ----------

func _place_furniture() -> void:
	# 床：1x2 格竖放，床头贴上墙。主角醒来的地方。
	_prop("res://assets/sprites/custom/bed.png", Vector2(80, 96), Vector2(28, 58), Vector2(0, -30))
	# 床边的检视点（睡下 → 序章火山爆发演出，eruption.dialogue/home_root 接管）
	var bed_prop: DialogueProp = preload("res://scenes/props/dialogue_prop.tscn").instantiate()
	bed_prop.name = "Prop_床"
	bed_prop.position = Vector2(84, 106)
	bed_prop.prompt = "睡下"
	bed_prop.dialogue = preload("res://resources/dialogue/town/eruption.dialogue")
	bed_prop.dialogue_title = "sleep"
	furniture.add_child(bed_prop)
	# 立柜：靠上墙（右上角）。
	_prop("res://assets/sprites/custom/cabinet.png", Vector2(432, 96), Vector2(28, 34), Vector2(0, -18))
	# 木桌：房间中央，桌上一盏油灯。
	var table := _prop("res://assets/sprites/custom/table.png", Vector2(256, 208), Vector2(44, 18), Vector2(0, -10))
	var lamp := Sprite2D.new()
	lamp.name = "Lamp"
	lamp.texture = load("res://assets/sprites/custom/lamp.png")
	lamp.position = Vector2(-10, -21)
	lamp.offset = Vector2(0, -5)
	table.add_child(lamp)
	# 圆凳：桌边。
	_prop("res://assets/sprites/custom/stool.png", Vector2(216, 224), Vector2(14, 8), Vector2(0, -4))
	# 木框窗：挂在墙面上，两扇（无碰撞，纯装饰）。
	_deco("res://assets/sprites/custom/window.png", Vector2(176, 48))
	_deco("res://assets/sprites/custom/window.png", Vector2(336, 48))
	# 门口地垫：下墙缺口处。
	_deco("res://assets/sprites/custom/door_mat.png", Vector2(256, 324))


## 带碰撞的家具：origin 在脚底中心，贴图向上画（和 house.gd 同一套路）。
func _prop(tex_path: String, pos: Vector2, collider_size: Vector2, collider_offset: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "Furn_" + tex_path.get_file().get_basename()
	body.position = pos
	body.collision_layer = 1
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load(tex_path)
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	body.add_child(sprite)
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = collider_size
	shape.shape = rect
	shape.position = collider_offset
	body.add_child(shape)
	furniture.add_child(body)
	return body


## 纯装饰贴图（无碰撞）。
func _deco(tex_path: String, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "Deco_" + tex_path.get_file().get_basename()
	sprite.texture = load(tex_path)
	sprite.position = pos
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	furniture.add_child(sprite)
	return sprite


# ---------- 玩家 / 物理墙 / 出门区 ----------

func _place_player() -> void:
	var player := preload("res://scenes/actors/player.tscn").instantiate()
	player.name = "Player"
	player.spawn_point = Vector2(108, 100)  # 床边（起身后的位置）
	player.position = player.spawn_point
	world.add_child(player)
	player.camera.limit_left = 0
	player.camera.limit_top = 0
	player.camera.limit_right = MAP_W * TILE
	player.camera.limit_bottom = MAP_H * TILE
	# 室内近景：2倍变焦（整数缩放不糊像素）。房间512×320 > 视野320×180，镜头可跟随平移。
	player.camera.zoom = Vector2(2, 2)


func _place_walls_and_door() -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	add_child(walls)
	# 四周墙：上墙盖住贴图墙两行；下墙在门口（x 224~288）留缺口
	_add_wall(walls, "Wall_上", Rect2(-16, -16, MAP_W * TILE + 32, 96))
	_add_wall(walls, "Wall_下左", Rect2(-16, 304, 240, 24))
	_add_wall(walls, "Wall_下右", Rect2(288, 304, 240, 24))
	_add_wall(walls, "Wall_左", Rect2(-24, 0, 32, MAP_H * TILE))
	_add_wall(walls, "Wall_右", Rect2(MAP_W * TILE - 8, 0, 32, MAP_H * TILE))
	_add_wall(walls, "Wall_门槛", Rect2(224, 320, 64, 16))
	# 出门区：踩到地垫附近 → home_root 切换到小镇
	var door := Area2D.new()
	door.name = "DoorZone"
	door.position = Vector2(256, 310)
	door.collision_layer = 0
	door.collision_mask = 4
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 24)
	shape.shape = rect
	door.add_child(shape)
	add_child(door)


func _add_wall(parent: Node, wall_name: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = wall_name
	body.position = rect.position + rect.size / 2.0
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var r := RectangleShape2D.new()
	r.size = rect.size
	shape.shape = r
	body.add_child(shape)
	parent.add_child(body)


## 暖色调光：室内比室外偏暖一点（石头房里的晨光）。
func _warm_tint() -> void:
	var warm := CanvasModulate.new()
	warm.name = "WarmTint"
	warm.color = Color(1.0, 0.94, 0.84)
	add_child(warm)
