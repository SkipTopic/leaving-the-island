class_name DialogueProp
extends StaticBody2D
## 检视点/剧情物件：交互 → 播放指定对话。检查器配 dialogue+title+prompt。
## sprite_texture 可选（留空=无外观，纯空气检视点）。

## 交互提示语
@export var prompt := "查看"
## 对话资源（.dialogue 拖进来）
@export var dialogue: DialogueResource
## 从哪个标题开始
@export var dialogue_title := "start"
## 外观贴图（可选）
@export var sprite_texture: Texture2D
## 外观纵向偏移
@export var sprite_offset := Vector2(0, -12)
## 碰撞（挡路）——默认不挡
@export var solid := false


func _ready() -> void:
	collision_layer = 1 if solid else 0
	collision_mask = 0
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	shape.position = Vector2(0, -5)
	add_child(shape)

	var area := Area2D.new()
	area.name = "InteractArea"
	area.collision_layer = 2
	area.collision_mask = 0
	var ashape := CollisionShape2D.new()
	var acircle := CircleShape2D.new()
	acircle.radius = 20.0
	ashape.shape = acircle
	ashape.position = Vector2(0, -8)
	area.add_child(ashape)
	add_child(area)

	if sprite_texture != null:
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = sprite_texture
		sprite.offset = sprite_offset
		add_child(sprite)


func prompt_text() -> String:
	return prompt


func interact(_player: Node) -> void:
	if Game.state != Game.State.PLAYING or dialogue == null:
		return
	Game.state = Game.State.DIALOGUE
	DialogueManager.show_dialogue_balloon(dialogue, dialogue_title)
	await DialogueManager.dialogue_ended
	Game.state = Game.State.PLAYING
