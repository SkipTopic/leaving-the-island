extends Node
## 复现用户报告的两个操作问题（诊断用，不进正式流程）：
##   ① 开场对话点鼠标无反应，只有键盘E有反应
##   ② 房间里 WASD / 屏幕摇杆都无法移动
## 运行: godot --headless --path <项目> res://tests/repro_user.tscn --quit-after 3000
## 判定看最后一行 "REPRO RESULT"。

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var home: Node = load("res://scenes/town/home_interior.tscn").instantiate()
	get_tree().root.add_child(home)
	await _sleep(1.5)  # 等开场黑屏呼唤的气球弹出

	_log("开场后 Game.state = %s" % _state_name(Game.state))
	for c in get_tree().root.get_children():
		_log("  root子节点: %s (%s)" % [c.name, c.get_class()])
	var balloon := _find_balloon()
	_log("对话气球存在 = %s" % (balloon != null))
	if balloon == null:
		_finish(1)
		return

	# --- 测① 鼠标左键点击气球，能否推进对话 ---
	var t := Time.get_ticks_msec()
	var clicks := 0
	while Game.state == Game.State.DIALOGUE and clicks < 8 and Time.get_ticks_msec() - t < 15000:
		_click(Vector2(320, 300))
		clicks += 1
		await _sleep(0.5)
	var click_ok := Game.state != Game.State.DIALOGUE
	_log("连点8下内对话结束 = %s（点了 %d 下，state=%s）" % [click_ok, clicks, _state_name(Game.state)])

	# 若点击无效，改用 E 键补完对话（= 用户实际做到的进度）
	t = Time.get_ticks_msec()
	while Game.state == Game.State.DIALOGUE and Time.get_ticks_msec() - t < 20000:
		_press_key(KEY_E)
		await _sleep(0.35)
	_log("E键补完后 state = %s" % _state_name(Game.state))

	# --- 测② WASD 移动（对话结束后理论上应回到 PLAYING）---
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if player == null:
		_log("找不到玩家")
		_finish(1)
		return
	# --- 玩家可见性（防"开场淡入后隐形"复发：visible 曾被隐藏后忘记恢复）---
	# 淡入 tween 0.3s，给 1.5s 墙钟等它播完
	var vis_t := Time.get_ticks_msec()
	while player.modulate.a < 0.99 and Time.get_ticks_msec() - vis_t < 1500:
		await _sleep(0.1)
	_check(player.visible, "开场后玩家可见")
	_check(player.modulate.a > 0.9, "开场后玩家淡入完成（a=%.2f）" % player.modulate.a)
	_check(player.global_position.distance_to(player.spawn_point) < 2.0,
		"开场后玩家在出生点（%s）" % str(player.global_position))
	_log("移动测试前 state = %s, player.state = %d" % [_state_name(Game.state), player.state])
	# 测②-A：真实 D 键事件（= 用户实际按法）
	var p0 := player.global_position
	var dn := InputEventKey.new()
	dn.physical_keycode = KEY_D
	dn.pressed = true
	_log("  InputMap直接匹配: event_is_action(move_right)=%s" % InputMap.event_is_action(dn, "move_right"))
	Input.parse_input_event(dn)
	await _sleep(0.1)
	_log("  解析后: is_action_pressed(move_right)=%s strength=%.2f vel=%s" % [
		Input.is_action_pressed("move_right"), Input.get_action_strength("move_right"), player.velocity])
	await _sleep(0.6)
	_log("  0.7秒后 pos=%s (起点 %s)" % [player.global_position, p0])
	var up_ev := InputEventKey.new()
	up_ev.physical_keycode = KEY_D
	up_ev.pressed = false
	Input.parse_input_event(up_ev)
	await _sleep(0.3)
	var d_kb := player.global_position.distance_to(p0)
	_log("D真实按键 1.4秒位移 = %.1f px" % d_kb)

	# 测②-B：直接 action_press（摇杆同款驱动路径）
	p0 = player.global_position
	Input.action_press("move_down", 1.0)
	await _sleep(0.1)
	for i in 3:
		_log("  action_press: strength_down=%.2f vel=%s pos=%s" % [
			Input.get_action_strength("move_right"), player.velocity, player.global_position])
		await _sleep(0.2)
	Input.action_release("move_down")
	var d_ap := player.global_position.distance_to(p0)
	_log("action_press 0.7秒位移 = %.1f px" % d_ap)

	# --- 测② 屏幕摇杆（左下角往下拖）---
	p0 = player.global_position
	_touch(Vector2(80, 250), true)
	await _sleep(0.15)
	_drag(Vector2(80, 250), Vector2(130, 300))
	await _sleep(1.0)
	_touch(Vector2(130, 300), false)
	var d_joy := player.global_position.distance_to(p0)
	_log("摇杆 1秒位移 = %.1f px" % d_joy)

	var code := 0 if (click_ok and d_kb > 10.0 and d_ap > 10.0 and d_joy > 10.0) else 1
	_log("REPRO RESULT: click=%s realW=%s actionPress=%s joy=%s → %s" % [click_ok, d_kb > 10.0, d_ap > 10.0, d_joy > 10.0, "OK" if code == 0 else "问题复现"])
	_finish(code)


# ---------- 工具 ----------

func _state_name(s: int) -> String:
	return ["BOOT", "TITLE", "PLAYING", "DIALOGUE", "BACKPACK", "CUTSCENE", "ENDING"][s]


func _find_balloon() -> Node:
	var bs := load("res://scenes/ui/dialogue_balloon.gd")
	for c in get_tree().root.get_children():
		if c.get_script() == bs:
			return c
	var found := get_tree().root.find_children("*", "CanvasLayer", true, false)
	for c in found:
		if c.get_script() == bs:
			return c
	return null


func _click(pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	ev.global_position = pos
	Input.parse_input_event(ev)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = pos
	up.global_position = pos
	Input.parse_input_event(up)


func _press_key(key: Key) -> void:
	var dn := InputEventKey.new()
	dn.physical_keycode = key
	dn.pressed = true
	Input.parse_input_event(dn)
	var up := InputEventKey.new()
	up.physical_keycode = key
	up.pressed = false
	Input.parse_input_event(up)


func _touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.position = pos
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _drag(from: Vector2, to: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = 0
	ev.position = to
	ev.relative = to - from
	Input.parse_input_event(ev)


func _sleep(sec: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < int(sec * 1000):
		await get_tree().process_frame


func _log(msg: String) -> void:
	print("[repro] ", msg)


func _check(cond: bool, what: String) -> void:
	_log("%s - %s" % ["ok" if cond else "FAIL", what])


func _finish(code: int) -> void:
	_log("退出码 %d" % code)
	get_tree().quit(code)
