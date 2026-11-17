@tool
class_name SaveWell
extends StaticBody2D
## 井台：存档点 + 回满血。交互文案不提"晚上"——存档现在只是生活的一部分。

## 提示语
@export var prompt := "井台 · 打水歇脚"
## 存档后的通知
@export var done_text := "打了一瓢凉水，精神多了。（已存档）"
## 外观贴图（留空=默认水井）
@export var sprite_texture: Texture2D

@onready var area: Area2D = $InteractArea
@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	if sprite_texture != null:
		sprite.texture = sprite_texture


func prompt_text() -> String:
	return prompt


func interact(player: Node) -> void:
	if Game.state != Game.State.PLAYING:
		return
	if player.has_method("heal"):
		player.heal(99)
	SaveSystem.save_slot(SaveSystem.AUTO_SLOT)
	Events.notify.emit(done_text)
