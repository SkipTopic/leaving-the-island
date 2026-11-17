class_name StoryZone
extends Area2D
## 剧情触发区：玩家踏入 → 播放指定对话（独白/过场通用）。
## 摆放方式：bake 建造脚本实例化，或编辑器里直接拖进场景。
## 串行剧情用 require_flag 指向前一段的 set_flag，防止玩家乱序抢先触发。

## 对话资源（.dialogue 拖进来）
@export var dialogue: DialogueResource
## 从哪个标题开始
@export var dialogue_title := "start"
## 触发后置位的剧情标记（也充当"只触发一次"的依据；留空则每次踏入都播）
@export var set_flag := ""
## 前置标记（未置位则不触发、不消耗）
@export var require_flag := ""
## 触发区尺寸（像素）
@export var zone_size := Vector2(64, 48)

var _busy := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4  # 只响应玩家层
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _busy or dialogue == null or not body.is_in_group("player"):
		return
	if Game.state != Game.State.PLAYING:
		return
	if Game.god_mode:
		return  # 上帝模式（调试）：跳过剧情触发区，走场景不被独白打断
	if set_flag != "" and Game.get_flag(set_flag) != null:
		return
	if require_flag != "" and Game.get_flag(require_flag) == null:
		return
	_busy = true
	Game.state = Game.State.DIALOGUE
	DialogueManager.show_dialogue_balloon(dialogue, dialogue_title)
	await DialogueManager.dialogue_ended
	Game.state = Game.State.PLAYING
	if set_flag != "":
		Game.set_flag(set_flag, true)
	_busy = false
