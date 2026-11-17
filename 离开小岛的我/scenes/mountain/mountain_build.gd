extends Node2D
## 上山之路「建造脚本」：30×170 纵向长图，五章同图（路牌/服务区/隧道/观景台/加油站/山口）。
## 由 tests/bake_town.gd 烘焙成 mountain_road.tscn。
##
## 公路重修（用户要求模仿真实高速俯视，如海南环岛高速）：
## - 路线=锚点+余弦插值的蜿蜒 S 弯（长直段+大半径缓弯），隧道段强制直；
## - 路面=深褐柏油（现代感）+中央白虚线（只画直行段，弯道断开）+两侧白实线；
## - 服务区/加油站有硬化地坪；服务区藏火山口大门密码；
## - 山口有"观测站大门"（密码在服务区纸条里，crater_code_found → crater_gate_open）。

const TILE := 32
const MAP_W := 30
const MAP_H := 170

const SRC_GRASS := 0
const SRC_PATH := 1
const SRC_GDET := 3
# 现代公路瓦片（town_tiles.tres source 9~12，gen_road_tiles.gd 生成）
const SRC_ASPHALT := 9
const SRC_DASH := 10
const SRC_EDGE_L := 11
const SRC_EDGE_R := 12

## 隧道区间（格，与 mountain_root.gd 的 TUNNEL_Y 一致）：内部强制直行
const TUNNEL_Y := Vector2(90, 114)
## 公路中心线锚点 [y, x]，南(168)→北(12)；相邻锚点间余弦插值出平缓弯道
const ROAD_POINTS := [
	[168, 15], [152, 15], [142, 20], [126, 20], [116, 10],
	[88, 10], [80, 16], [68, 21], [56, 16], [48, 9],
	[36, 15], [24, 15], [12, 15],
]
## 服务区/加油站硬化地坪（柏油铺装）
const SERVICE_AREA := Rect2i(12, 117, 7, 9)
const GAS_AREA := Rect2i(3, 42, 12, 7)
## 路半宽（格）：路面 5 格宽 = 2 车道 + 中央线
const ROAD_HALF := 2

@onready var ground: TileMapLayer = $Ground
@onready var world: Node2D = $World
@onready var props: Node2D = $World/Props
@onready var trees: Node2D = $World/Trees
@onready var enemies: Node2D = $World/Enemies

var rng := RandomNumberGenerator.new()

var _house_scene := preload("res://scenes/props/house.tscn")
var _tree_scene := preload("res://scenes/props/tree.tscn")
var _sign_scene := preload("res://scenes/props/sign_post.tscn")
var _well_scene := preload("res://scenes/props/well.tscn")
var _dprop_scene := preload("res://scenes/props/dialogue_prop.tscn")
var _player_scene := preload("res://scenes/actors/player.tscn")
var _boar_scene := preload("res://scenes/actors/boar.tscn")
var _bird_scene := preload("res://scenes/actors/bird.tscn")
var _pickup_scene := preload("res://scenes/actors/pickup.tscn")

var _road_dialogue := preload("res://resources/dialogue/mountain/road.dialogue")
var _obs_dialogue := preload("res://resources/dialogue/mountain/observatory.dialogue")


func build() -> void:
	rng.seed = 20261031
	_build_ground()
	_place_trees()
	_zone_road()      # A 路牌+野猪
	_zone_service()   # B 一号服务区（+火山口大门密码纸条）
	_zone_tunnel()    # C 望海隧道
	_zone_observatory() # D 观景台
	_zone_gas()       # E 加油站
	_zone_crater()    # 山口 + 观测站大门
	_place_player()
	_place_walls()
	_place_exits()


## 公路中心线 x（格，浮点）。相邻锚点间余弦缓入缓出插值 → 大半径缓弯。
func _road_x(y: float) -> float:
	if y >= float(ROAD_POINTS[0][0]):
		return float(ROAD_POINTS[0][1])
	if y <= float(ROAD_POINTS[-1][0]):
		return float(ROAD_POINTS[-1][1])
	for i in ROAD_POINTS.size() - 1:
		var a: Array = ROAD_POINTS[i]
		var b: Array = ROAD_POINTS[i + 1]
		if y <= float(a[0]) and y >= float(b[0]):
			var t := (float(a[0]) - y) / (float(a[0]) - float(b[0]))
			t = (1.0 - cos(t * PI)) / 2.0
			return float(a[1]) + (float(b[1]) - float(a[1])) * t
	return 15.0


## 该行是否近直行（中线虚线只画直行段——真实公路弯道标线会断）
func _is_straight(y: int) -> bool:
	var cx := _road_x(y)
	if absf(cx - float(int(round(cx)))) > 0.2:
		return false
	if absf(_road_x(y - 2) - cx) > 0.6 or absf(_road_x(y + 2) - cx) > 0.6:
		return false
	return true


func _in_rect(x: int, y: int, r: Rect2i) -> bool:
	return x >= r.position.x and x < r.end.x and y >= r.position.y and y < r.end.y


func tile_center(x: float, y: float) -> Vector2:
	return Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)


func _build_ground() -> void:
	for y in MAP_H:
		var cx := _road_x(y)
		var cxi := int(round(cx))
		for x in MAP_W:
			var on_road := x >= cxi - ROAD_HALF and x <= cxi + ROAD_HALF
			var on_pad := _in_rect(x, y, SERVICE_AREA) or _in_rect(x, y, GAS_AREA)
			if on_road:
				# 现代柏油路面：边缘白实线 + 中央白虚线（直行段）
				var v := SRC_ASPHALT
				if x == cxi - ROAD_HALF:
					v = SRC_EDGE_L
				elif x == cxi + ROAD_HALF:
					v = SRC_EDGE_R
				elif x == cxi and _is_straight(y) \
						and not _in_rect(x, y, SERVICE_AREA) and not _in_rect(x, y, GAS_AREA):
					v = SRC_DASH
				ground.set_cell(Vector2i(x, y), v, Vector2i(0, 0))
			elif on_pad:
				# 服务区/加油站硬化地坪
				ground.set_cell(Vector2i(x, y), SRC_ASPHALT, Vector2i(0, 0))
			else:
				ground.set_cell(Vector2i(x, y), SRC_GRASS, Vector2i(0, 0))
				if rng.randf() < 0.06:
					ground.set_cell(Vector2i(x, y), SRC_GDET, Vector2i(rng.randi_range(0, 5), 0))


func _place_trees() -> void:
	var paths := [
		"res://assets/tilesets/village_topdown_2x/TREE 1 - DAY_2x.png",
		"res://assets/tilesets/village_topdown_2x/TREE 2 - DAY_2x.png",
		"res://assets/tilesets/village_topdown_2x/TREE 3 - DAY_2x.png",
	]
	var idx := 0
	for y in range(2, MAP_H - 2):
		for x in [1, 2, 27, 28]:
			var inst := _tree_scene.instantiate()
			inst.name = "Tree_%03d" % idx
			idx += 1
			inst.position = tile_center(x, y) + Vector2(rng.randf_range(-6, 6), 14 + rng.randf_range(-8, 8))
			inst.tree_texture = load(paths[rng.randi_range(0, 2)])
			trees.add_child(inst)


func _dprop(prop_name: String, pos: Vector2, prompt: String, title: String, tex_path := "") -> DialogueProp:
	var d: DialogueProp = _dprop_scene.instantiate()
	d.name = prop_name
	d.position = pos
	d.prompt = prompt
	d.dialogue = _road_dialogue if title in ["kettle", "vending", "tunnel_hint", "sulfur", "gate_code", "crater_gate"] else _obs_dialogue
	d.dialogue_title = title
	if tex_path != "":
		d.sprite_texture = load(tex_path)
	props.add_child(d)
	return d


# ---------------- A 路牌 ----------------
func _zone_road() -> void:
	var sign := _sign_scene.instantiate()
	sign.name = "SignPost_路牌"
	sign.position = tile_center(_road_x(162) + 2.5, 162)
	sign.sign_text = "前方2公里，一号服务区。——我不知道什么叫服务区。我猜，是集市。"
	props.add_child(sign)
	_boar(_road_x(155) - 5, 155)
	_boar(_road_x(153) + 5, 153)
	PickupHelper(_road_x(159) - 5, 159, "stone")
	PickupHelper(_road_x(158) + 5, 158, "stone")


# ---------------- B 一号服务区（硬化地坪，路西侧） ----------------
func _zone_service() -> void:
	var house := _house_scene.instantiate()
	house.name = "House_一号服务区"
	house.position = tile_center(14.5, 123)
	house.house_texture = load("res://assets/tilesets/village_topdown_2x/HOUSE 1 - DAY_2x.png")
	house.collider_size = Vector2(150, 60)
	house.collider_offset = Vector2(0, -34)
	props.add_child(house)

	var log := _well_scene.instantiate()
	log.name = "SavePoint_值班日志"
	log.position = tile_center(13, 124.5)
	log.prompt = "值班日志 · 歇脚"
	log.done_text = "水循环，正常。电压，正常。（已存档）"
	log.sprite_texture = load("res://assets/sprites/custom/book.png")
	props.add_child(log)

	# 火山口大门的密码就藏在这（crater_code_found）
	_dprop("Prop_值班纸条", tile_center(16.5, 124), "压在桌角的纸条", "gate_code",
		"res://assets/sprites/custom/book.png")
	_dprop("Prop_开水间", tile_center(16.5, 118), "开水间", "kettle")
	PickupHelper(12.5, 118, "map")


# ---------------- C 望海隧道（内部强制直行） ----------------
func _zone_tunnel() -> void:
	_dprop("Prop_隧道口", tile_center(_road_x(113) + 2.5, 113), "洞口", "tunnel_hint")
	var poster := _sign_scene.instantiate()
	poster.name = "SignPost_海报"
	poster.position = tile_center(_road_x(104) + 2.5, 104)
	poster.sign_text = "墙上的旧海报：一个男人指着冒烟的山，笑得一嘴白牙——「欢迎登岛。山顶见。」"
	props.add_child(poster)


# ---------------- D 观景台 ----------------
func _zone_observatory() -> void:
	_dprop("Prop_望远镜", tile_center(_road_x(70) + 2.5, 70), "投币望远镜", "scope", "")
	# 灯亮演出触发区（mountain_root 接管）
	var area := Area2D.new()
	area.name = "Trigger_灯亮"
	area.position = tile_center(_road_x(64), 64)
	area.collision_layer = 0
	area.collision_mask = 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(150, 40)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	_bird(_road_x(75) - 5, 75)
	_bird(_road_x(72) + 4, 72)


# ---------------- E 加油站（硬化地坪） ----------------
func _zone_gas() -> void:
	_dprop("Prop_贩卖机", tile_center(5, 44), "会嗡嗡响的机器", "vending")
	for i in [[4, 46], [13, 46]]:
		var tank := StaticBody2D.new()
		tank.name = "OilTank_%d" % i[0]
		tank.position = tile_center(i[0], i[1])
		tank.collision_layer = 1
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load("res://assets/sprites/custom/crate.png")
		sprite.scale = Vector2(3, 3)
		sprite.offset = Vector2(0, -6)
		tank.add_child(sprite)
		var shape := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(30, 20)
		shape.shape = r
		shape.position = Vector2(0, -10)
		tank.add_child(shape)
		props.add_child(tank)
	# 落石触发区
	var area := Area2D.new()
	area.name = "Trigger_落石"
	area.position = tile_center(_road_x(38), 38)
	area.collision_layer = 0
	area.collision_mask = 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(150, 40)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	_boar(_road_x(33) + 5, 33)


# ---------------- 山口 + 观测站大门（密码在服务区） ----------------
func _zone_crater() -> void:
	_dprop("Prop_硫磺味", tile_center(_road_x(26), 26), "山口", "sulfur")
	# 观测站大门：物理挡路；对它交互输密码（crater_gate_open）后由 mountain_root 移除。
	# 上帝模式也会自动开门。
	var gate := StaticBody2D.new()
	gate.name = "CraterGate"
	gate.position = tile_center(_road_x(18) + 0.5, 18)
	gate.collision_layer = 1
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load("res://assets/tilesets/generated/road_gate.png")
	sprite.offset = Vector2(0, -28)
	gate.add_child(sprite)
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var r := RectangleShape2D.new()
	r.size = Vector2(160, 22)
	shape.shape = r
	shape.position = Vector2(0, -12)
	gate.add_child(shape)
	props.add_child(gate)
	# 门前交互点
	_dprop("Prop_观测站大门", tile_center(_road_x(19) + 0.5, 19.5), "观测站大门", "crater_gate")

	var marker := Marker2D.new()
	marker.name = "FromOffice"
	marker.position = tile_center(_road_x(12), 12)
	add_child(marker)
	var from_world := Marker2D.new()
	from_world.name = "FromWorldMap"
	from_world.position = tile_center(_road_x(168), 168)
	add_child(from_world)


func _place_player() -> void:
	var player := _player_scene.instantiate()
	player.name = "Player"
	player.spawn_point = tile_center(_road_x(168), 168)
	player.position = player.spawn_point
	world.add_child(player)
	player.camera.limit_left = 0
	player.camera.limit_top = 0
	player.camera.limit_right = MAP_W * TILE
	player.camera.limit_bottom = MAP_H * TILE


## 南北出口（此前一直缺失，玩家进了山道出不去——本轮补上）：
## 南→世界地图（落 FromCrater），北→办公区（落 FromMountain；先过观测站大门）。
func _place_exits() -> void:
	_exit_area("SouthExit", Vector2(_road_x(168.8), 168.8), Vector2(MAP_W * TILE, 28))
	_exit_area("NorthExit", Vector2(_road_x(2), 2), Vector2(MAP_W * TILE, 28))


func _exit_area(exit_name: String, cell: Vector2, size: Vector2) -> void:
	var area := Area2D.new()
	area.name = exit_name
	area.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
	area.collision_layer = 0
	area.collision_mask = 4
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var r := RectangleShape2D.new()
	r.size = size
	shape.shape = r
	area.add_child(shape)
	add_child(area)


func _place_walls() -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	add_child(walls)
	_block(walls, "Wall_左", Rect2(-8, 0, 2.2 * TILE, MAP_H * TILE))
	_block(walls, "Wall_右", Rect2((MAP_W - 1.2) * TILE, 0, 2.2 * TILE, MAP_H * TILE))
	_block(walls, "Wall_上", Rect2(0, -16, MAP_W * TILE, 32))
	_block(walls, "Wall_下", Rect2(0, (MAP_H - 0.5) * TILE, MAP_W * TILE, 32))


func _block(parent: Node, block_name: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = block_name
	body.position = rect.position + rect.size / 2.0
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	shape.shape = r
	body.add_child(shape)
	parent.add_child(body)


func _boar(x: float, y: float) -> void:
	var b := _boar_scene.instantiate()
	b.name = "Boar_%.0f_%.0f" % [x, y]
	b.position = tile_center(x, y)
	enemies.add_child(b)


func _bird(x: float, y: float) -> void:
	var b := _bird_scene.instantiate()
	b.name = "Bird_%.0f_%.0f" % [x, y]
	b.position = tile_center(x, y)
	enemies.add_child(b)


func PickupHelper(x: float, y: float, id: String) -> void:
	var p := _pickup_scene.instantiate()
	p.name = "Pickup_%s_%.0f" % [id, y]
	p.item_id = id
	p.position = tile_center(x, y)
	$World/Pickups.add_child(p)
