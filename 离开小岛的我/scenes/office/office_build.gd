extends Node2D
## 火山办公区「建造脚本」（室内）：大厅→门禁解谜→三房间+红门→站台。烘焙成 office.tscn。

const TILE := 32
const MAP_W := 34
const MAP_H := 22

const SRC_PATH := 1   # 深色地面
const SRC_GRASS := 0

@onready var ground: TileMapLayer = $Ground
@onready var props: Node2D = $World/Props

var _dprop_scene := preload("res://scenes/props/dialogue_prop.tscn")
var _pickup_scene := preload("res://scenes/actors/pickup.tscn")
var _well_scene := preload("res://scenes/props/well.tscn")
var _office_dialogue := preload("res://resources/dialogue/office/office.dialogue")


func build() -> void:
	for c in [props, $World/Enemies, $World/Pickups]:
		for child in c.get_children():
			child.queue_free()
	for y in MAP_H:
		for x in MAP_W:
			ground.set_cell(Vector2i(x, y), SRC_PATH, Vector2i(0, 0))
	_place_hall()
	_place_doors()
	_place_rooms()
	_place_platform()
	_place_player()
	_place_walls()


func tile_center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)


func _dprop(prop_name: String, pos: Vector2, prompt: String, title: String, tex: String = "res://assets/sprites/custom/crate.png") -> DialogueProp:
	var d: DialogueProp = _dprop_scene.instantiate()
	d.name = prop_name
	d.position = pos
	d.prompt = prompt
	d.dialogue = _office_dialogue
	d.dialogue_title = title
	if tex != "":
		d.sprite_texture = load(tex)
	props.add_child(d)
	return d


## 大厅：成排的桌子（电脑）+ 手册 + 桌垫下的纸条
func _place_hall() -> void:
	for i in 4:
		var desk := StaticBody2D.new()
		desk.name = "Desk_%d" % i
		desk.position = tile_center(7 + i * 6, 12)
		desk.collision_layer = 1
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load("res://assets/sprites/custom/crate.png")
		sprite.scale = Vector2(2, 1.5)
		sprite.offset = Vector2(0, -6)
		desk.add_child(sprite)
		var shape := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(60, 18)
		shape.shape = r
		shape.position = Vector2(0, -9)
		desk.add_child(shape)
		props.add_child(desk)
	_dprop("Prop_值班员手册", tile_center(7, 14), "桌上的蓝皮册子", "manual", "res://assets/sprites/custom/book.png")
	_dprop("Prop_桌垫纸条", tile_center(13, 13), "桌垫之下", "password", "")
	var pc := _dprop("Prop_电脑", tile_center(19, 13), "玻璃板子（电脑）", "pc", "res://assets/sprites/custom/crate.png")
	pc.set_meta("is_pc", true)
	_dprop("Prop_恒温茶杯", tile_center(25, 13), "恒温底座上的茶杯", "tea", "")
	# 真相三件套（揭示后才能看）
	_dprop("Prop_飞行记录仪", tile_center(22, 12), "架子第三层的铁盒子", "recorder", "res://assets/sprites/custom/crate.png")
	_dprop("Prop_值班日志", tile_center(28, 14), "写满「正常」的日志", "nightlog", "res://assets/sprites/custom/book.png")
	_dprop("Prop_投影录像", tile_center(25, 15), "值班录像", "tape", "")


## 三扇白门：doors_open 后由 office_root 移除；后面是三个房间
func _place_doors() -> void:
	for i in 3:
		var door := StaticBody2D.new()
		door.name = "Door_%d" % i
		door.position = tile_center(8 + i * 8, 8)
		door.collision_layer = 1
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load("res://assets/tilesets/village_topdown_2x/HOUSE 1 - DAY_2x.png")
		sprite.scale = Vector2(0.28, 0.28)
		sprite.offset = Vector2(0, -120)
		door.add_child(sprite)
		var shape := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(52, 14)
		shape.shape = r
		shape.position = Vector2(0, -7)
		door.add_child(shape)
		props.add_child(door)


func _place_rooms() -> void:
	_dprop("Prop_仓库相册", tile_center(8, 4), "木箱上的相册", "album")
	_dprop("Prop_宿舍床铺", tile_center(16, 4), "八张叠得方方正正的床", "beds", "")
	_dprop("Prop_机器房", tile_center(24, 4), "满屋子嗡嗡响的铁柜子", "machines", "")
	# 红门：永远锁着
	var red := _dprop("Prop_红门", tile_center(29, 8), "最深处的那扇门", "red_door", "res://assets/tilesets/village_topdown_2x/HOUSE 2 - DAY_2x.png")
	red.sprite_texture = load("res://assets/tilesets/village_topdown_2x/HOUSE 2 - DAY_2x.png")
	red.modulate = Color(0.9, 0.35, 0.3)


func _place_platform() -> void:
	# 站台（矿车）在最北；通讯机房（电台）在东北
	_dprop("Prop_矿车站台", tile_center(6, 1), "镇区线 · 矿车", "minecart")
	_dprop("Prop_电台", tile_center(27, 1), "老频率的电台", "radio")
	var from_m := Marker2D.new()
	from_m.name = "FromMountain"
	from_m.position = tile_center(17, 19)
	add_child(from_m)
	var from_reveal := Marker2D.new()
	from_reveal.name = "FromReveal"
	from_reveal.position = tile_center(6, 3)
	add_child(from_reveal)


func _place_player() -> void:
	var player := preload("res://scenes/actors/player.tscn").instantiate()
	player.name = "Player"
	player.position = tile_center(17, 19)
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
	_block(walls, "Wall_上", Rect2(0, -12, MAP_W * TILE, 24))
	_block(walls, "Wall_下", Rect2(0, (MAP_H - 0.4) * TILE, MAP_W * TILE, 24))
	_block(walls, "Wall_左", Rect2(-12, 0, 24, MAP_H * TILE))
	_block(walls, "Wall_右", Rect2((MAP_W - 0.4) * TILE, 0, 24, MAP_H * TILE))
	# 大厅与北部分隔墙：三个门洞
	_block(walls, "Divider_左", Rect2(0, 6.6 * TILE, 6.6 * TILE, 20))
	_block(walls, "Divider_中1", Rect2(9.4 * TILE, 6.6 * TILE, 4.6 * TILE, 20))
	_block(walls, "Divider_中2", Rect2(17.4 * TILE, 6.6 * TILE, 4.6 * TILE, 20))
	_block(walls, "Divider_右", Rect2(26.4 * TILE, 6.6 * TILE, 7.6 * TILE, 20))


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
