extends Node2D
## 结局场景通用根脚本（ending_silence / ending_reply 共用）。
## 演出全部写在 .dialogue 文件里（检查器里换 dialogue 即可复用）；
## 本脚本只负责：黑屏 → 开场字幕段 → 淡入 → 正片段 → staff roll → 回标题。
## 场景里的节点（钢琴/阿蓝/少校/Marker）全部可在编辑器里拖动调整。

@export_group("演出")
## 对话资源（结局台词都在这里改）
@export var dialogue: DialogueResource
## 开场黑屏段标题（播完才淡入场景）
@export var black_cue := "black"
## 黑屏后依次播放的段标题（段间气球自动闭合）
@export var walk_cues: PackedStringArray = PackedStringArray(["walk"])
## 场景边界（相机限位）
@export var bounds := Rect2(0, 0, 768, 448)
## 演出自动开始（冒烟测试/编辑器预览场景内容时可关掉）
@export var auto_play := true

const STAFF_ROLL := preload("res://scenes/ending/staff_roll.tscn")


func _ready() -> void:
	Game.state = Game.State.CUTSCENE
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if player != null:
		player.camera.limit_left = int(bounds.position.x)
		player.camera.limit_top = int(bounds.position.y)
		player.camera.limit_right = int(bounds.end.x)
		player.camera.limit_bottom = int(bounds.end.y)
	if auto_play:
		_run()


func _run() -> void:
	# 1) 黑幕：全程先压黑
	var layer := CanvasLayer.new()
	layer.layer = 80
	var black := ColorRect.new()
	black.name = "Black"
	black.color = Color(0, 0, 0, 1)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	add_child(layer)

	# 2) 黑屏字幕段（对应挑战信号/应答那几行）
	Game.state = Game.State.DIALOGUE
	DialogueManager.show_dialogue_balloon(dialogue, black_cue)
	await DialogueManager.dialogue_ended

	# 3) 淡入场景，走正片段
	var tw := create_tween()
	tw.tween_property(black, "color:a", 0.0, 0.8)
	await tw.finished
	layer.queue_free()

	for cue in walk_cues:
		Game.state = Game.State.DIALOGUE
		DialogueManager.show_dialogue_balloon(dialogue, cue)
		await DialogueManager.dialogue_ended

	# 4) staff roll（可点击跳过，滚完自动回标题）
	Game.state = Game.State.CUTSCENE
	add_child(STAFF_ROLL.instantiate())
