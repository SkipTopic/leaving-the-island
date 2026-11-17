class_name Villager
extends CharacterBody2D
## 透明镇民：人物半透明（shader），手持物不透明悬浮（扫帚/木箱/钢笔）。
## 也兼职狗子等小动物（没有对话时交互给一句提示）。
## 对话资源直接在检查器里把 .dialogue 文件拖到 Dialogue 槽。

@export_group("身份")
@export var npc_name := "镇民" ## 名字（交互提示显示）
@export var dialogue: DialogueResource ## 对话资源（留空=只给一句通用提示）
@export var dialogue_title := "start" ## 从哪个标题开始
@export var no_dialogue_text := "（他似乎没有要说的。）" ## 没有对话时的提示

@export_group("外观")
@export var sheet: Texture2D ## 立绘（Pipoya 3x4 行走表）
@export var tint := Color.WHITE ## 调色（比如陈婆的灰白发色感）
@export_range(0.5, 2.0) var sprite_scale := 1.0 ## 体型缩放（小孩用0.8）
@export var held_texture: Texture2D ## 手持物贴图（留空=空手）
@export var held_offset := Vector2(0, -30) ## 手持物相对位置
## 幽灵透明（幻想镇民=true；实体人物如结局二的少校=false）
@export var ghost := true:
	set(value):
		ghost = value
		_update_ghost()

@export_group("巡逻")
@export var patrol_points: PackedVector2Array ## 巡逻点（≥2个来回走，留空=站着）
@export_range(10.0, 120.0) var walk_speed := 30.0 ## 巡逻速度
@export_range(2.0, 16.0) var walk_fps := 7.0 ## 走路动画帧率

var _sprite: Sprite2D
var _held: Sprite2D
var _held_base_y := 0.0
var _anim_t := 0.0
var _patrol_i := 0
var _pause_t := 0.0
var _time := 0.0

const _WALK_SEQ := [0, 1, 2, 1]

@onready var interact_area: Area2D = $InteractArea


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	_sprite = $Sprite
	_sprite.texture = sheet
	_sprite.modulate = tint
	_sprite.scale = Vector2.ONE * sprite_scale
	_update_ghost()
	if held_texture != null:
		_held = $HeldItem
		_held.texture = held_texture
		_held.position = held_offset
		_held_base_y = held_offset.y
	else:
		$HeldItem.visible = false
	_patrol_i = 0
	_pause_t = 0.0


## ghost=false 时摘掉场景自带的透明 shader（实体人物用）。
func _update_ghost() -> void:
	if _sprite == null:
		return
	if not ghost:
		_sprite.material = null


func _physics_process(delta: float) -> void:
	_time += delta
	if _held != null:
		_held.position.y = _held_base_y + sin(_time * 2.2) * 1.5

	# 巡逻只在可玩时自主走；演出中（StageDirector）直接驱动 velocity，这里不抢
	if patrol_points.size() >= 2 and Game.state == Game.State.PLAYING and velocity == Vector2.ZERO:
		var target := patrol_points[_patrol_i]
		var to_target := target - global_position
		if _pause_t > 0.0:
			_pause_t -= delta
			velocity = Vector2.ZERO
		elif to_target.length() < 4.0:
			_patrol_i = (_patrol_i + 1) % patrol_points.size()
			_pause_t = randf_range(1.2, 2.4)
			velocity = Vector2.ZERO
		else:
			velocity = to_target.normalized() * walk_speed
	_animate(delta)
	move_and_slide()


func _animate(delta: float) -> void:
	var row := 0
	if absf(velocity.x) > absf(velocity.y):
		row = 1 if velocity.x < 0 else 2
	elif velocity.y < 0:
		row = 3
	if velocity.length() > 4.0:
		_anim_t += delta * walk_fps
		_sprite.frame = row * 3 + _WALK_SEQ[int(_anim_t) % 4]
	else:
		_sprite.frame = row * 3 + 1


func prompt_text() -> String:
	return npc_name


func interact(_player: Node) -> void:
	if Game.state != Game.State.PLAYING:
		return
	if dialogue == null:
		Events.notify.emit(no_dialogue_text)
		return
	Game.state = Game.State.DIALOGUE
	DialogueManager.show_dialogue_balloon(dialogue, dialogue_title)
	await DialogueManager.dialogue_ended
	Game.state = Game.State.PLAYING
