extends Node2D
## 我家室内运行时根脚本（烘焙后 home_interior.tscn 用它）。
## 负责：开场演出（黑屏外婆呼唤 → 淡入 → 起身）+ 床上的序章爆发演出 + 踩门垫回小镇。

const INTRO := preload("res://resources/dialogue/town/intro.dialogue")
const ERUPTION := preload("res://resources/dialogue/town/eruption.dialogue")
const BLACK_LAYER := 80   # 黑幕层级：压过 HUD(50)，让位对话气球(90)

var _sleep_busy := false


func _process(_delta: float) -> void:
	# 床检视点置位 sleep_requested → 接管演出（爆发/回笼觉）
	if not _sleep_busy and Game.get_flag("sleep_requested") != null:
		_sleep_busy = true
		Game.set_flag("sleep_requested", false)
		_run_sleep()


## 床上演出：第一次睡 = 序章·火山爆发（第四章语料）；之后 = 回笼觉小段。
func _run_sleep() -> void:
	var layer := CanvasLayer.new()
	layer.layer = BLACK_LAYER
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	add_child(layer)
	Game.state = Game.State.CUTSCENE

	if Game.get_flag("eruption_seen") == null:
		# --- 序章·火山爆发 ---
		Game.set_flag("eruption_seen", true)
		var tw := create_tween()
		tw.tween_property(black, "color:a", 1.0, 0.6)
		await tw.finished
		Game.state = Game.State.DIALOGUE
		DialogueManager.show_dialogue_balloon(ERUPTION, "eruption")
		await DialogueManager.dialogue_ended
		# 天亮：淡入室内，晨段收束
		var tw2 := create_tween()
		tw2.tween_property(black, "color:a", 0.0, 0.9)
		await tw2.finished
		layer.queue_free()
		Game.state = Game.State.DIALOGUE
		DialogueManager.show_dialogue_balloon(ERUPTION, "morning")
		await DialogueManager.dialogue_ended
	else:
		# --- 回笼觉 ---
		var tw := create_tween()
		tw.tween_property(black, "color:a", 1.0, 0.5)
		await tw.finished
		await get_tree().create_timer(0.6).timeout
		Game.state = Game.State.DIALOGUE
		DialogueManager.show_dialogue_balloon(ERUPTION, "nap")
		await DialogueManager.dialogue_ended
		var tw2 := create_tween()
		tw2.tween_property(black, "color:a", 0.0, 0.5)
		await tw2.finished
		layer.queue_free()

	Game.state = Game.State.PLAYING
	_sleep_busy = false


func _ready() -> void:
	Game.state = Game.State.CUTSCENE
	add_child(GameHUD.new())
	var door := get_node_or_null("DoorZone") as Area2D
	if door != null:
		door.body_entered.connect(_on_door_entered)
	_run_intro()


## 开场序列（T1-b）：黑屏呼唤 → 淡入 → 起身出现 → 提示移动。
## intro_wake_done 置位后跳过（死亡在室内重载时不再播）。
func _run_intro() -> void:
	# 黑幕：开场永远全黑起手（转场层 100 在其上，切场景不受影响）
	var layer := CanvasLayer.new()
	layer.layer = BLACK_LAYER
	var black := ColorRect.new()
	black.name = "Black"
	black.color = Color(0, 0, 0, 1)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	add_child(layer)

	if Game.get_flag("intro_wake_done") != null:
		layer.queue_free()
		Game.state = Game.State.PLAYING
		return

	# 1) 黑屏中：外婆的呼唤（气球当字幕用）
	Game.state = Game.State.DIALOGUE
	DialogueManager.show_dialogue_balloon(INTRO, "wake_call")
	await DialogueManager.dialogue_ended

	# 2) 淡入室内（主角还"躺在床上"，先不显示）
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if player != null:
		player.visible = false
	var tw := create_tween()
	tw.tween_property(black, "color:a", 0.0, 0.9)
	await tw.finished
	layer.queue_free()

	# 3) 起身（简化演出）：主角在床边淡入
	if player != null:
		await get_tree().create_timer(0.5).timeout
		player.global_position = player.spawn_point
		player.visible = true  # 第2步藏人后必须恢复——曾漏掉这行导致玩家全程隐形
		player.modulate.a = 0.0
		var tw2 := create_tween()
		tw2.tween_property(player, "modulate:a", 1.0, 0.3)
	Game.set_flag("intro_wake_done", true)
	Events.notify.emit("太阳都晒到屁股啦——先出门吧。")
	Game.state = Game.State.PLAYING


## 踩到门垫 → 去小镇，落点=我家门口。
func _on_door_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or Game.state != Game.State.PLAYING:
		return
	Game.pending_spawn = "FromHome"
	Game.change_scene("res://scenes/town/town.tscn")
