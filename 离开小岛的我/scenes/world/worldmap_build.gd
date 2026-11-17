extends Node2D
## 世界地图「建造脚本」（FF7 式）：只能通过 tests/bake_town.gd 烘焙成 worldmap.tscn。
## 岛屿全图：南边小镇，北边火山（剧情解锁前进不去）。

const TILE := 32
const MAP_W := 40
const MAP_H := 28

# G草 P路 W水
const MAP := [
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGPPPPPPPGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
]

const SRC_GRASS := 0
const SRC_PATH := 1
const SRC_WATER := 2
const SRC_GDET := 3
const SRC_PDET := 4
const SRC_WDET := 5
# 草地变体源（town_tiles.tres 里新加的三个程序化色调，gen_grass_variants.gd 生成）
const SRC_GRASS_DARK := 6
const SRC_GRASS_LIGHT := 7
const SRC_GRASS_PATCH := 8

# —— 草地噪声散布（与 town_build 同一套参数；种子不同让两图色块不一样）——
## 噪声频率：越小深浅色块越大
const GRASS_NOISE_FREQ := 0.09
## 深浅阈值：噪声值超过 ±此值 换浅草/深草
const GRASS_TONE_TH := 0.28
## 杂色草皮阈值：二次采样超过此值铺杂色块
const GRASS_PATCH_TH := 0.12

@onready var ground: TileMapLayer = $Ground
@onready var props: Node2D = $World/Props
@onready var trees: Node2D = $World/Trees
@onready var locations: Node2D = $World/Locations

var rng := RandomNumberGenerator.new()
## 草地噪声场（build() 里初始化；固定种子保证每次烘焙一致）
var _grass_noise: FastNoiseLite


## 草地噪声采样：offset 让深浅/杂色两套色块错开
func _grass_n(x: int, y: int, offset := 0) -> float:
	return _grass_noise.get_noise_2d(x + offset, y + offset)


## 是否基底草（撒花草饰只落在基底草上，避免饰块底色与变体色调接缝）
func _is_base_grass(x: int, y: int) -> bool:
	return absf(_grass_n(x, y)) <= GRASS_PATCH_TH

var _house_scene := preload("res://scenes/props/house.tscn")
var _tree_scene := preload("res://scenes/props/tree.tscn")
var _player_scene := preload("res://scenes/actors/player.tscn")
var _gate_script := preload("res://scenes/world/location_gate.gd")

# Pipoya 世界图集区域（32px格）
const ATLAS_PATH := "res://assets/tilesets/pipoya_world_32/pipo-map001.png"
const REGION_VOLCANO := Rect2(192, 128, 64, 64)
const REGION_MTN_GRAY := Rect2(0, 128, 64, 64)
const REGION_MTN_ROCK := Rect2(128, 128, 64, 64)


func build() -> void:
	rng.seed = 20261031
	_grass_noise = FastNoiseLite.new()
	_grass_noise.seed = 20261032  # 与小镇不同种子，两张图色块分布不一样
	_grass_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_grass_noise.frequency = GRASS_NOISE_FREQ
	for c in [props, trees, locations]:
		for child in c.get_children():
			child.queue_free()
	# —— Y-sort 全链开启（同 town_build：父链每层都要开）——
	var world_node := get_node_or_null("World")
	if world_node != null:
		world_node.y_sort_enabled = true
	for c in [props, trees, locations]:
		c.y_sort_enabled = true
	_build_ground()
	_place_volcano_and_ridge()
	_place_town_marker()
	_place_locations()
	_place_trees()
	_place_player()
	_place_walls()
	_place_markers()


## 落点标记：从小镇回来 / （未来）从火山口回来
func _place_markers() -> void:
	var from_town := Marker2D.new()
	from_town.name = "FromTown"
	from_town.position = Vector2(28.5 * TILE, 21.0 * TILE)
	add_child(from_town)
	var from_crater := Marker2D.new()
	from_crater.name = "FromCrater"
	from_crater.position = Vector2(20.5 * TILE, 9.5 * TILE)
	add_child(from_crater)


func tile_center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)


func tile_char(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= MAP_W or y >= MAP_H:
		return "W"
	return MAP[y][x]


func _build_ground() -> void:
	for y in MAP_H:
		for x in MAP_W:
			var c := tile_char(x, y)
			match c:
				"P":
					ground.set_cell(Vector2i(x, y), SRC_PATH, Vector2i(0, 0))
				"W":
					ground.set_cell(Vector2i(x, y), SRC_WATER, Vector2i(0, 0))
				_:
					# 草地噪声散布：深浅成团 + 杂色斑块，替代单一草砖
					var n := _grass_n(x, y)
					if n > GRASS_TONE_TH:
						ground.set_cell(Vector2i(x, y), SRC_GRASS_LIGHT, Vector2i(0, 0))
					elif n < -GRASS_TONE_TH:
						ground.set_cell(Vector2i(x, y), SRC_GRASS_DARK, Vector2i(0, 0))
					elif absf(n) > GRASS_PATCH_TH:
						# 过渡带：基底与深浅之间的杂色草皮，让色块边界更碎更自然
						ground.set_cell(Vector2i(x, y), SRC_GRASS_PATCH, Vector2i(0, 0))
					else:
						ground.set_cell(Vector2i(x, y), SRC_GRASS, Vector2i(0, 0))
	for y in MAP_H:
		for x in MAP_W:
			var c := tile_char(x, y)
			var r := rng.randf()
			match c:
				"G":
					# 花草石饰只撒在基底草上（变体色调上会有底色接缝）
					if r < 0.07 and _is_base_grass(x, y):
						ground.set_cell(Vector2i(x, y), SRC_GDET, Vector2i(rng.randi_range(0, 5), 0))
				"P":
					if r < 0.06:
						ground.set_cell(Vector2i(x, y), SRC_PDET, Vector2i(rng.randi_range(0, 4), 0))
				"W":
					if y == 25 and r < 0.2:
						ground.set_cell(Vector2i(x, y), SRC_WDET, Vector2i(rng.randi_range(0, 4), 0))


## 火山 + 山脊（北边一排，中间留出火山口闸门的口子）
func _place_volcano_and_ridge() -> void:
	var ridge := Node2D.new()
	ridge.name = "火山山脊"
	props.add_child(ridge)
	_mountain(ridge, "Volcano", REGION_VOLCANO, Vector2(19.0 * TILE, 2.0 * TILE))
	_mountain(ridge, "Mountain_左灰", REGION_MTN_GRAY, Vector2(14.0 * TILE, 2.5 * TILE))
	_mountain(ridge, "Mountain_右岩", REGION_MTN_ROCK, Vector2(24.5 * TILE, 2.5 * TILE))
	# 山体碰撞：玩家不能翻山，只留中间一条火山口甬道
	_add_block(ridge, "Ridge_左", Rect2(2 * TILE, 2 * TILE, 17 * TILE, 4 * TILE))
	_add_block(ridge, "Ridge_右", Rect2(22 * TILE, 2 * TILE, 16 * TILE, 4 * TILE))
	_add_block(ridge, "Ridge_顶", Rect2(2 * TILE, 1 * TILE, 36 * TILE, 1.4 * TILE))


func _mountain(parent: Node, mt_name: String, region: Rect2, pos: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = mt_name
	body.position = pos + region.size  # 山脚为锚点
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load(ATLAS_PATH)
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = Vector2(2, 2)
	sprite.offset = Vector2(0, -region.size.y / 2.0)
	body.add_child(sprite)
	parent.add_child(body)


func _add_block(parent: Node, block_name: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = block_name
	body.position = rect.position + rect.size / 2.0
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var r := RectangleShape2D.new()
	r.size = rect.size
	shape.shape = r
	body.add_child(shape)
	parent.add_child(body)


## 小镇：世界地图上的家（真正的场景入口）
func _place_town_marker() -> void:
	var house := _house_scene.instantiate()
	house.name = "TownMarker_小镇"
	house.position = Vector2(28.5 * TILE, 24.0 * TILE)
	house.house_texture = load("res://assets/tilesets/village_topdown_2x/HOUSE 1 - DAY_2x.png")
	house.collider_size = Vector2(152, 60)
	house.collider_offset = Vector2(0, -34)
	props.add_child(house)


func _place_locations() -> void:
	_add_gate("Loc_小镇", tile_center(27, 24), {
		"display_name": "小镇",
		"target_scene": "res://scenes/town/town.tscn",
		"spawn_point_name": "FromWorld",
	})
	_add_gate("Loc_火山口", tile_center(20, 7), {
		"display_name": "上山之路",
		"target_scene": "res://scenes/mountain/mountain_road.tscn",
		"spawn_point_name": "FromWorldMap",
		"unlock_flag": "allowed_up_mountain",
		"locked_text": "火山还在喷发，这时候上去就是送死。（先去会堂找老校长聊聊）",
	})
	_add_gate("Loc_东林子", tile_center(34, 13), {
		"display_name": "东林子",
		"unlock_flag": "flag_never",
		"locked_text": "林子太密了，钻不进去。（剧情开放）",
	})


func _add_gate(gate_name: String, pos: Vector2, cfg: Dictionary) -> void:
	var gate: LocationGate = _gate_script.new()
	gate.name = gate_name
	gate.position = pos
	gate.display_name = cfg.get("display_name", "？？？")
	gate.target_scene = cfg.get("target_scene", "")
	gate.spawn_point_name = cfg.get("spawn_point_name", "")
	gate.unlock_flag = cfg.get("unlock_flag", "")
	gate.locked_text = cfg.get("locked_text", "还过不去。")
	gate.unlocked_text = cfg.get("unlocked_text", "（还没做好）")
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	shape.shape = circle
	shape.position = Vector2(0, -8)
	gate.add_child(shape)
	var label := Label.new()
	label.name = "NameLabel"
	label.text = "· " + gate.display_name + " ·"
	label.position = Vector2(-48, -44)
	label.size = Vector2(96, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(1, 1, 0.85, 0.85)
	gate.add_child(label)
	locations.add_child(gate)


func _place_trees() -> void:
	var tree_paths := [
		"res://assets/tilesets/village_topdown_2x/TREE 1 - DAY_2x.png",
		"res://assets/tilesets/village_topdown_2x/TREE 2 - DAY_2x.png",
		"res://assets/tilesets/village_topdown_2x/TREE 3 - DAY_2x.png",
	]
	var idx := 0
	for y in range(6, 25):
		for x in range(2, 38):
			if tile_char(x, y) != "G":
				continue
			if Rect2i(17, 2, 11, 7).has_point(Vector2i(x, y)):  # 火山脚下不种
				continue
			if Rect2i(24, 17, 9, 9).has_point(Vector2i(x, y)):  # 小镇附近不种
				continue
			if rng.randf() < 0.10:
				var inst := _tree_scene.instantiate()
				inst.name = "Tree_%03d" % idx
				idx += 1
				inst.position = tile_center(x, y) + Vector2(rng.randf_range(-8, 8), 10)
				inst.tree_texture = load(tree_paths[rng.randi_range(0, 2)])
				trees.add_child(inst)


func _place_player() -> void:
	var player := _player_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(28.5 * TILE, 22.0 * TILE)
	world_add(player)
	player.camera.limit_left = 0
	player.camera.limit_top = 0
	player.camera.limit_right = MAP_W * TILE
	player.camera.limit_bottom = MAP_H * TILE


func world_add(node: Node) -> void:
	$World.add_child(node)


func _place_walls() -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	add_child(walls)
	_add_block(walls, "Wall_上水域", Rect2(0, 0, MAP_W * TILE, 2.2 * TILE))
	_add_block(walls, "Wall_下水域", Rect2(0, 25.8 * TILE, MAP_W * TILE, 2.2 * TILE))
	_add_block(walls, "Wall_左水域", Rect2(0, 0, 1.8 * TILE, MAP_H * TILE))
	_add_block(walls, "Wall_右水域", Rect2(38.2 * TILE, 0, 1.8 * TILE, MAP_H * TILE))
