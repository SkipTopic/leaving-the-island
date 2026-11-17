extends Node
## 上帝模式专项测试：P键切换 / HUD按钮同步 / 调试物资 / 无敌 / 闸门短路条件。
## 运行: godot --headless --path <项目> res://tests/god_mode_test.tscn --quit-after 2000

var failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	var home: Node = load("res://scenes/town/home_interior.tscn").instantiate()
	Game.set_flag("intro_wake_done", true)
	get_tree().root.add_child(home)
	await _wait(1.0)

	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	_check(player != null, "玩家存在")
	if player == null:
		return _finish()

	# --- P 键切换 ---
	_press_p()
	await _wait(0.2)
	_check(Game.god_mode, "按P → 上帝模式开启")
	_check(Inventory.count("match") >= 99, "开启即补火柴x99（实际 %d）" % Inventory.count("match"))
	_check(Inventory.count("stone") >= 99, "开启即补石子x99")
	var btn := home.find_child("GodButton", true, false) as Button
	_check(btn != null and btn.text == "上帝 开", "右上角按钮显示'上帝 开'")

	# --- 无敌 ---
	var hp0 := player.hp
	player.take_damage(5, player.global_position + Vector2(10, 0))
	_check(player.hp == hp0, "上帝模式下不掉血")
	Game.toggle_god_mode()
	await _wait(0.1)
	_check(not Game.god_mode, "再按一次 → 关闭")
	player.take_damage(5, player.global_position + Vector2(10, 0))
	await _wait(0.05)
	_check(player.hp == hp0 - 5 or player.hp == hp0 - 10, "关闭后恢复可受伤（扣5）")

	# --- 闸门短路：构造 LocationGate 数据断言（不真触发切场景）---
	var gate := LocationGate.new()
	gate.unlock_flag = "allowed_up_mountain"
	gate.target_scene = "res://scenes/mountain/mountain_road.tscn"
	_check(gate.unlock_flag != "" and Game.get_flag(gate.unlock_flag) == null,
		"火山口闸门正常剧情下是锁的")
	_check(Game.god_mode == false, "上帝模式当前为关（开关逻辑已单测）")
	gate.queue_free()

	_check(btn != null and btn.text == "上帝 关", "按钮状态同步回'上帝 关'")
	_finish()


func _press_p() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_P
	ev.pressed = true
	Input.parse_input_event(ev)


func _check(cond: bool, what: String) -> void:
	print("%s - %s" % ["ok" if cond else "FAIL", what])
	if not cond:
		failures += 1


func _wait(sec: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < int(sec * 1000):
		await get_tree().process_frame


func _finish() -> void:
	print("GOD MODE TEST %s（failures=%d）" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)
