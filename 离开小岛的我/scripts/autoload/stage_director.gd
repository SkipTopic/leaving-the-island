extends Node
## 演出导演：对话/剧情事件的原语。
## 在 .dialogue 里用 `do StageDirector.move_npc("阿豆", "NPC_老校长", Vector2(-40, 0))` 调用。
## 异步原语会被 Dialogue Manager await——NPC 走到位后才会说下一句（RPG Maker 式演出）。

## 让某个角色走到另一角色身边（offset 为相对目标脚下的偏移）。
## mover/target 都按节点名在当前场景里找。
func move_npc(mover_name: String, target_name: String, offset := Vector2(-36, 0), speed := 130.0) -> void:
	var mover: Node2D = _find_node(mover_name)
	var target: Node2D = _find_node(target_name)
	if mover == null or target == null:
		push_warning("StageDirector.move_npc 找不到节点: %s / %s" % [mover_name, target_name])
		return
	var goal := target.global_position + offset
	if mover is CharacterBody2D:
		# 只设速度不亲自位移——角色自己的 _physics_process 会 move_and_slide（避免双重移动）
		var body := mover as CharacterBody2D
		var guard := 10.0
		while body.global_position.distance_to(goal) > 4.0 and guard > 0.0:
			guard -= get_physics_process_delta_time()
			body.velocity = (goal - body.global_position).normalized() * speed
			await get_tree().physics_frame
		body.velocity = Vector2.ZERO
	else:
		var tw := create_tween()
		tw.tween_property(mover, "global_position", goal, mover.global_position.distance_to(goal) / speed)
		await tw.finished


## 演出停顿（秒）。
func wait(seconds: float) -> void:
	await get_tree().create_timer(maxf(0.05, seconds)).timeout


## 相机震动（雷声/爆发/砸落）。
func shake_camera(strength := 4.0, duration := 0.4) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var cam: Camera2D = null
	if player != null and "camera" in player:
		cam = player.camera
	if cam == null:
		return
	var t := 0.0
	while t < duration:
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength
		t += get_process_delta_time()
		await get_tree().process_frame
	cam.offset = Vector2.ZERO


## 全屏闪光（爆发瞬间/白昼闪电）。color 带透明度。
func flash(color := Color(1, 1, 1, 0.8), duration := 0.3) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 95
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	add_child(layer)
	var tw := create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, duration)
	await tw.finished
	layer.queue_free()


## 屏幕小提示（对话里也可用）。
func notify(text: String) -> void:
	Events.notify.emit(text)


## 先搜当前场景，再搜整棵树（兼容测试环境）。
func _find_node(node_name: String) -> Node2D:
	var scene := get_tree().current_scene
	if scene != null:
		var n := scene.find_child(node_name, true, false)
		if n != null:
			return n
	return get_tree().root.find_child(node_name, true, false)
