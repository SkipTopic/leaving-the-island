extends Node2D
## 小镇「建造脚本」—— 只被 bake 工具调用一次，把内容物实例化。
## 烘焙完成后 town.tscn 就是纯场景文件，本脚本不再参与运行。
## 改地图/改摆放 → 改这里或直接改 town.tscn，两种方式都行（见协作指南）。

const TILE := 32
const MAP_W := 44
const MAP_H := 30

# 我家门口（House_我家占 x5-9/y9-15，门口在房底中点下一格）：
# 室内出门落点 FromHome、玩家出生点（死亡重载）都用它。
const HOME_DOOR := Vector2(7.5 * TILE, 16.4 * TILE)

# 地块图例：G草 P路 W水 F田土
const MAP := [
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGPPPPPPPPPPPPPGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGPGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGPGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGPGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGPGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGPGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGPGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGPGGGGGG",
	"GGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGG",
	"GGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGFFFFFFFGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGFFFFFFFGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGFFFFFFFGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGFFFFFFFGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
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

# —— 草地噪声散布（视觉：草皮深浅成团，避免大面均一）——
## 噪声频率：越小深浅色块越大
const GRASS_NOISE_FREQ := 0.11
## 深浅阈值：噪声值超过 ±此值 换浅草/深草
const GRASS_TONE_TH := 0.28
## 杂色草皮阈值：二次采样超过此值铺杂色块
const GRASS_PATCH_TH := 0.12

# 房屋：贴图 / 左上角格子(w,h为格数)
const HOUSES := [
	{"tex": "res://assets/tilesets/village_topdown_2x/HOUSE 1 - DAY_2x.png", "cells": Vector2i(5, 9), "size": Vector2i(5, 7), "name": "House_我家"},
	{"tex": "res://assets/tilesets/village_topdown_2x/HOUSE 2 - DAY_2x.png", "cells": Vector2i(25, 9), "size": Vector2i(8, 7), "name": "House_陈婆小卖部"},
	{"tex": "res://assets/tilesets/village_topdown_2x/CHURCH - DAY_2x.png", "cells": Vector2i(34, 2), "size": Vector2i(8, 7), "name": "House_会堂"},
	{"tex": "res://assets/tilesets/village_topdown_2x/HOUSE 1 - DAY_2x.png", "cells": Vector2i(2, 18), "size": Vector2i(5, 7), "name": "House_老校长家"},
	{"tex": "res://assets/tilesets/village_topdown_2x/HOUSE 1 - DAY_2x.png", "cells": Vector2i(13, 18), "size": Vector2i(5, 7), "name": "House_六叔家"},
]

# 树避开门口/码头口
const TREE_EXCLUDE := [
	Vector2i(4, 25), Vector2i(15, 25), Vector2i(7, 17), Vector2i(28, 16),
	Vector2i(37, 16), Vector2i(8, 24), Vector2i(9, 24),
]

var _house_scene := preload("res://scenes/props/house.tscn")
var _tree_scene := preload("res://scenes/props/tree.tscn")
var _well_scene := preload("res://scenes/props/well.tscn")
var _sign_scene := preload("res://scenes/props/sign_post.tscn")
var _dprop_scene := preload("res://scenes/props/dialogue_prop.tscn")
var _player_scene := preload("res://scenes/actors/player.tscn")
var _boar_scene := preload("res://scenes/actors/boar.tscn")
var _villager_scene := preload("res://scenes/actors/villager.tscn")
var _pickup_scene := preload("res://scenes/actors/pickup.tscn")

@onready var ground: TileMapLayer = $Ground
@onready var world: Node2D = $World
@onready var buildings: Node2D = $World/Buildings
@onready var trees: Node2D = $World/Trees
@onready var fences: Node2D = $World/Fences
@onready var props: Node2D = $World/Props
@onready var npcs: Node2D = $World/NPCs
@onready var enemies: Node2D = $World/Enemies
@onready var pickups: Node2D = $World/Pickups

var rng := RandomNumberGenerator.new()
## 草地噪声场（build() 里初始化；固定种子保证每次烘焙一致）
var _grass_noise: FastNoiseLite


## 草地噪声采样：offset 让深浅/杂色两套色块错开
func _grass_n(x: int, y: int, offset := 0) -> float:
	return _grass_noise.get_noise_2d(x + offset, y + offset)


## 是否基底草（撒花草饰只落在基底草上，避免饰块底色与变体色调接缝）
func _is_base_grass(x: int, y: int) -> bool:
	return absf(_grass_n(x, y)) <= GRASS_PATCH_TH


## 由 bake_town.gd 调用；幂等（先清空再建）。
func build() -> void:
	rng.seed = 20261031
	_grass_noise = FastNoiseLite.new()
	_grass_noise.seed = 20261031
	_grass_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_grass_noise.frequency = GRASS_NOISE_FREQ
	for c in [buildings, trees, fences, props, npcs, enemies, pickups]:
		for child in c.get_children():
			child.queue_free()
	# —— Y-sort 全链开启（修"房子盖住玩家"）——
	# Godot4 的 y_sort 只排直接子节点：父链每一层都要开，容器里的房子/树/村民才会
	# 和玩家（同为 World 直接子孙）按脚底 y 全局排序。参考 godotengine#12339。
	world.y_sort_enabled = true
	for c in [buildings, trees, fences, props, npcs, enemies, pickups]:
		c.y_sort_enabled = true
	_build_ground()
	_place_houses()
	_place_farm_fence()
	_place_trees()
	_place_dock()
	_place_props()
	_place_intro_zones()
	_place_npcs()
	_place_enemies()
	_place_pickups()
	_place_player()
	_place_water_and_borders()


## 空镇揭示变体（由 bake 调用）：去掉NPC + 夜色 + 检视点。
func build_reveal() -> void:
	build()
	var npc_container := get_node_or_null("World/NPCs")
	if npc_container != null:
		for c in npc_container.get_children():
			c.free()
	# 空镇里没有"家"的独白——开场触发区一并去掉（跳过排队删除的旧节点防重删）
	for c in props.get_children():
		if c.name.begins_with("IntroZone_") and not c.is_queued_for_deletion():
			c.free()
	var night := CanvasModulate.new()
	night.name = "NightModulate"
	night.color = Color(0.32, 0.35, 0.52)
	add_child(night)
	var reveal := preload("res://resources/dialogue/town/reveal.dialogue")
	_reveal_point(reveal, "Prop_街心", tile_center(15, 9), "街心", "street")
	_reveal_point(reveal, "Prop_小卖部", tile_center(28, 17), "陈婆小卖部", "shop")
	_reveal_point(reveal, "Prop_六叔的船", tile_center(9, 24), "六叔的船", "boat")
	_reveal_point(reveal, "Prop_老校长家", tile_center(4, 25), "老校长的屋子", "school")
	_reveal_point(reveal, "Prop_坟头", tile_center(2, 8), "山坡上的坟", "graves")
	_reveal_point(reveal, "Prop_镇公所", tile_center(37, 11), "镇公所", "records")
	_reveal_point(reveal, "Prop_床底洞", tile_center(7, 17), "床底下的洞", "bed_note")
	var m := Marker2D.new()
	m.name = "FromMinecart"
	m.position = tile_center(7, 17)
	add_child(m)


func _reveal_point(dialogue: DialogueResource, prop_name: String, pos: Vector2, prompt: String, title: String) -> void:
	var d: DialogueProp = _dprop_scene.instantiate()
	d.name = prop_name
	d.position = pos
	d.prompt = prompt
	d.dialogue = dialogue
	d.dialogue_title = title
	props.add_child(d)


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
				"F":
					ground.set_cell(Vector2i(x, y), SRC_PATH, Vector2i(0, 0))
				_:
					# 草地噪声散布：深/浅色块 + 过渡杂色带（边缘不生硬），替代单一草砖
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
					if r < 0.085 and _is_base_grass(x, y):
						ground.set_cell(Vector2i(x, y), SRC_GDET, Vector2i(rng.randi_range(0, 5), 0))
				"P":
					if r < 0.06:
						ground.set_cell(Vector2i(x, y), SRC_PDET, Vector2i(rng.randi_range(0, 4), 0))
				"W":
					if y == 26 and r < 0.2:
						ground.set_cell(Vector2i(x, y), SRC_WDET, Vector2i(rng.randi_range(0, 4), 0))


func _place_houses() -> void:
	for h in HOUSES:
		var inst := _house_scene.instantiate()
		inst.name = h["name"]
		var size: Vector2i = h["size"]
		var cells: Vector2i = h["cells"]
		var w_px := size.x * TILE
		var h_px := size.y * TILE
		inst.position = Vector2((cells.x + size.x / 2.0) * TILE, (cells.y + size.y) * TILE)
		inst.house_texture = load(h["tex"])
		inst.collider_size = Vector2(w_px - 8, h_px - 36)
		# 碰撞盒下延到贴图最底（含门垫台阶）：台阶区不可站。
		# 否则玩家能站进台阶区、脚底 y 却排在房子前面之上，会被房子盖住（Y-sort 临界）。
		inst.collider_offset = Vector2(0, -(h_px - 36) / 2.0)
		buildings.add_child(inst)


func _place_farm_fence() -> void:
	var rect := Rect2i(24, 18, 9, 6)
	var cells: Array[Vector2i] = []
	for x in range(rect.position.x, rect.end.x):
		cells.append(Vector2i(x, rect.position.y))
		cells.append(Vector2i(x, rect.end.y - 1))
	for y in range(rect.position.y, rect.end.y):
		cells.append(Vector2i(rect.position.x, y))
		cells.append(Vector2i(rect.end.x - 1, y))
	for cell in cells:
		var body := StaticBody2D.new()
		body.name = "Fence_%d_%d" % [cell.x, cell.y]
		body.position = tile_center(cell.x, cell.y) + Vector2(0, 8)
		body.collision_layer = 1
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load("res://assets/tilesets/village_topdown_2x/FENCE 1 - DAY_2x.png")
		sprite.offset = Vector2(0, -8)
		body.add_child(sprite)
		var shape := CollisionShape2D.new()
		shape.name = "Shape"
		var r := RectangleShape2D.new()
		r.size = Vector2(26, 8)
		shape.shape = r
		shape.position = Vector2(0, -4)
		body.add_child(shape)
		fences.add_child(body)


func _place_trees() -> void:
	var tree_paths := [
		"res://assets/tilesets/village_topdown_2x/TREE 1 - DAY_2x.png",
		"res://assets/tilesets/village_topdown_2x/TREE 2 - DAY_2x.png",
		"res://assets/tilesets/village_topdown_2x/TREE 3 - DAY_2x.png",
	]
	var idx := 0
	for x in MAP_W:
		if x >= 20 and x <= 23:
			continue
		_add_tree(idx, Vector2(x * TILE + 16 + rng.randf_range(-5, 5), 58), tree_paths)
		idx += 1
		if rng.randf() < 0.55:
			_add_tree(idx, Vector2(x * TILE + 16 + rng.randf_range(-8, 8), 92), tree_paths)
			idx += 1
	for y in range(3, 25):
		for x in [0, 1, 42, 43]:
			if rng.randf() < 0.62:
				_add_tree(idx, Vector2(x * TILE + 16 + rng.randf_range(-6, 6), y * TILE + 24 + rng.randf_range(-6, 6)), tree_paths)
				idx += 1
	for x in MAP_W:
		if rng.randf() < 0.3:
			_add_tree(idx, Vector2(x * TILE + 16 + rng.randf_range(-6, 6), 25 * TILE + 24), tree_paths)
			idx += 1


func _add_tree(idx: int, base_pos: Vector2, tree_paths: Array) -> void:
	var cell := Vector2i(int(base_pos.x / TILE), int((base_pos.y + 6) / TILE))
	if cell in TREE_EXCLUDE:
		return
	if tile_char(cell.x, cell.y) != "G":
		return
	if Rect2i(23, 17, 11, 8).has_point(cell):
		return
	var inst := _tree_scene.instantiate()
	inst.name = "Tree_%03d" % idx
	inst.position = base_pos
	inst.tree_texture = load(tree_paths[rng.randi_range(0, 2)])
	trees.add_child(inst)


func _place_dock() -> void:
	var dock := StaticBody2D.new()
	dock.name = "Dock"
	dock.position = Vector2(8.5 * TILE, 27.5 * TILE)
	dock.collision_layer = 0
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load("res://assets/tilesets/village_topdown_2x/BRIDGE - DAY_2x.png")
	sprite.rotation = PI / 2.0
	dock.add_child(sprite)
	props.add_child(dock)
	var end_wall := StaticBody2D.new()
	end_wall.name = "DockEndWall"
	end_wall.position = Vector2(8.5 * TILE, 29 * TILE + 20)
	end_wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(96, 16)
	shape.shape = rect
	end_wall.add_child(shape)
	props.add_child(end_wall)


func _place_props() -> void:
	var sign := _sign_scene.instantiate()
	sign.name = "SignPost_北出口"
	sign.position = Vector2(23.5 * TILE, 2.2 * TILE)
	sign.sign_text = "镇北 · 出镇就是环岛的路。世界地图，从这儿看。"
	props.add_child(sign)

	var well := _well_scene.instantiate()
	well.name = "SaveWell_井台"
	well.position = tile_center(11, 17) + Vector2(0, 10)
	props.add_child(well)

	# 会堂门口的立式钢琴（阿蓝的琴，全镇不许它沾灰）——摆在屋檐线以南，避免被房体贴图盖住
	var piano := StaticBody2D.new()
	piano.name = "Prop_钢琴"
	piano.position = Vector2(36.4 * TILE, 9.6 * TILE)
	piano.collision_layer = 1
	var psprite := Sprite2D.new()
	psprite.name = "Sprite"
	psprite.texture = load("res://assets/sprites/custom/piano.png")
	psprite.offset = Vector2(0, -15)
	piano.add_child(psprite)
	var pshape := CollisionShape2D.new()
	pshape.name = "Shape"
	var prect := RectangleShape2D.new()
	prect.size = Vector2(44, 18)
	pshape.shape = prect
	pshape.position = Vector2(0, -9)
	piano.add_child(pshape)
	props.add_child(piano)

	var marker := Marker2D.new()
	marker.name = "FromWorld"
	marker.position = Vector2(22 * TILE, 2.6 * TILE)
	add_child(marker)

	# 我家出门落点（室内 → 小镇）
	var from_home := Marker2D.new()
	from_home.name = "FromHome"
	from_home.position = HOME_DOOR
	add_child(from_home)


## 开场世界观独白触发区（T1-b-4）：出门几步一段，严格串行（require_flag 链）。
## 语料=八章稿第一章，文本在 resources/dialogue/town/intro.dialogue，零硬编码。
func _place_intro_zones() -> void:
	var intro: DialogueResource = load("res://resources/dialogue/town/intro.dialogue")
	_story_zone(intro, "out_1", Vector2(7.5 * TILE, 17.4 * TILE), "intro_out_1", "", Vector2(72, 56))
	_story_zone(intro, "out_2", Vector2(9.5 * TILE, 17.5 * TILE), "intro_out_2", "intro_out_1", Vector2(64, 72))
	_story_zone(intro, "out_3", Vector2(21.5 * TILE, 8.8 * TILE), "intro_out_3", "intro_out_2", Vector2(96, 64))


func _story_zone(dialogue: DialogueResource, title: String, pos: Vector2, set_flag: String, require_flag: String, size: Vector2) -> void:
	var zone := StoryZone.new()
	zone.name = "IntroZone_" + title
	zone.position = pos
	zone.dialogue = dialogue
	zone.dialogue_title = title
	zone.set_flag = set_flag
	zone.require_flag = require_flag
	zone.zone_size = size
	props.add_child(zone)


func _place_npcs() -> void:
	var chenpo := _villager_scene.instantiate()
	chenpo.name = "NPC_陈婆"
	chenpo.position = Vector2(28.5 * TILE, 17.6 * TILE)
	chenpo.npc_name = "陈婆"
	chenpo.sheet = load("res://assets/sprites/pipoya/Female/Female 01-1.png")
	chenpo.tint = Color(0.93, 0.88, 0.86)
	chenpo.held_texture = load("res://assets/sprites/custom/crate.png")
	chenpo.held_offset = Vector2(6, -30)
	chenpo.dialogue = load("res://resources/dialogue/town/chenpo.dialogue")
	chenpo.dialogue_title = "start"
	npcs.add_child(chenpo)

	var teacher := _villager_scene.instantiate()
	teacher.name = "NPC_老校长"
	teacher.position = tile_center(37, 10)
	teacher.npc_name = "老校长"
	teacher.sheet = load("res://assets/sprites/pipoya/Male/Male 05-1.png")
	teacher.tint = Color(0.82, 0.82, 0.88)
	teacher.no_dialogue_text = "（老校长推了推并不存在的眼镜。）"
	teacher.dialogue = load("res://resources/dialogue/town/laoxiaozhang.dialogue")
	teacher.dialogue_title = "start"
	npcs.add_child(teacher)

	var adou := _villager_scene.instantiate()
	adou.name = "NPC_阿豆"
	adou.position = tile_center(31, 3)
	adou.npc_name = "阿豆"
	adou.sheet = load("res://assets/sprites/pipoya/Male/Male 03-1.png")
	adou.sprite_scale = 0.8
	adou.dialogue = load("res://resources/dialogue/town/adou.dialogue")
	adou.dialogue_title = "start"
	npcs.add_child(adou)

	var aunt := _villager_scene.instantiate()
	aunt.name = "NPC_大婶"
	aunt.position = tile_center(14, 18)
	aunt.npc_name = "扫地的婶子"
	aunt.sheet = load("res://assets/sprites/pipoya/Female/Female 02-1.png")
	aunt.tint = Color(0.9, 0.92, 0.95)
	aunt.held_texture = load("res://assets/sprites/custom/broom.png")
	aunt.held_offset = Vector2(9, -26)
	aunt.dialogue = load("res://resources/dialogue/town/dani.dialogue")
	aunt.dialogue_title = "start"
	aunt.patrol_points = PackedVector2Array([tile_center(14, 18), tile_center(26, 18)])
	npcs.add_child(aunt)

	# 六叔：码头渔民（硬汉，房梁救人=主角记忆里的恩人，幻想镇民）
	var liushu := _villager_scene.instantiate()
	liushu.name = "NPC_六叔"
	liushu.position = tile_center(9, 25)
	liushu.npc_name = "六叔"
	liushu.sheet = load("res://assets/sprites/pipoya/Male/Male 07-1.png")
	liushu.tint = Color(0.85, 0.8, 0.76)
	liushu.held_texture = load("res://assets/sprites/custom/net.png")
	liushu.held_offset = Vector2(10, -24)
	liushu.dialogue = load("res://resources/dialogue/town/liushu.dialogue")
	liushu.dialogue_title = "start"
	npcs.add_child(liushu)

	# 阿蓝：会堂钢琴师（白裙，幻想镇民；"白裙子"日常梗见 alan.dialogue）
	var alan := _villager_scene.instantiate()
	alan.name = "NPC_阿蓝"
	alan.position = Vector2(38.8 * TILE, 9.7 * TILE)
	alan.npc_name = "阿蓝"
	alan.sheet = load("res://assets/sprites/pipoya/Female/Female 03-1.png")
	alan.tint = Color(0.97, 0.95, 0.98)
	alan.sprite_scale = 0.92
	alan.dialogue = load("res://resources/dialogue/town/alan.dialogue")
	alan.dialogue_title = "start"
	npcs.add_child(alan)

	var dog := _villager_scene.instantiate()
	dog.name = "NPC_狗子"
	dog.position = tile_center(11, 23)
	dog.npc_name = "狗子"
	dog.sheet = load("res://assets/sprites/pipoya/Animal/Dog 01-1r.png")
	dog.no_dialogue_text = "（狗子摇了摇尾巴。）"
	dog.patrol_points = PackedVector2Array([tile_center(11, 23), tile_center(6, 23), tile_center(9, 21)])
	dog.walk_speed = 45.0
	npcs.add_child(dog)


func _place_enemies() -> void:
	var spots := [Vector2i(11, 21), Vector2i(36, 21), Vector2i(23, 22)]
	for i in spots.size():
		var boar := _boar_scene.instantiate()
		boar.name = "Boar_%d" % (i + 1)
		boar.position = tile_center(spots[i].x, spots[i].y)
		enemies.add_child(boar)


func _place_pickups() -> void:
	var items := [
		{"id": "candy", "cell": Vector2i(31, 17)},
		{"id": "stone", "cell": Vector2i(6, 25)},
		{"id": "stone", "cell": Vector2i(11, 24)},
	]
	for i in items.size():
		var p := _pickup_scene.instantiate()
		p.name = "Pickup_%d" % (i + 1)
		p.item_id = items[i]["id"]
		p.position = tile_center(items[i]["cell"].x, items[i]["cell"].y)
		pickups.add_child(p)


func _place_player() -> void:
	var player := _player_scene.instantiate()
	player.name = "Player"
	player.spawn_point = HOME_DOOR  # 家门口（T1 开场后死亡也回这儿）
	player.position = player.spawn_point
	world.add_child(player)
	player.camera.limit_left = 0
	player.camera.limit_top = 0
	player.camera.limit_right = MAP_W * TILE
	player.camera.limit_bottom = MAP_H * TILE


func _place_water_and_borders() -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	add_child(walls)
	_add_wall(walls, "Wall_水左", Rect2(0, 26 * TILE, 7 * TILE, 4 * TILE))
	_add_wall(walls, "Wall_水右", Rect2(10 * TILE, 26 * TILE, 34 * TILE, 4 * TILE))
	_add_wall(walls, "Wall_上", Rect2(-16, -32, MAP_W * TILE + 32, 44))
	_add_wall(walls, "Wall_下", Rect2(-16, MAP_H * TILE - 8, MAP_W * TILE + 32, 44))
	_add_wall(walls, "Wall_左", Rect2(-24, -32, 36, MAP_H * TILE + 64))
	_add_wall(walls, "Wall_右", Rect2(MAP_W * TILE - 8, -32, 36, MAP_H * TILE + 64))

	var exit_area := Area2D.new()
	exit_area.name = "NorthExit"
	exit_area.position = tile_center(21, 1) + Vector2(16, 0)
	exit_area.collision_layer = 0
	exit_area.collision_mask = 4
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 40)
	shape.shape = rect
	exit_area.add_child(shape)
	add_child(exit_area)


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
