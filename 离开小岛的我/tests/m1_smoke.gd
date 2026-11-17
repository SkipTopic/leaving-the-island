extends Node
## M1 冒烟测试：加载小镇 → 陈婆对话全链 → 道具/战斗/存档自检。
## 运行: godot --headless --path <项目> res://tests/m1_smoke.tscn --quit-after 3600
## 通过时打印 "M1 SMOKE PASS"，失败打印 "M1 SMOKE FAIL: 原因"。

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	var town: Node = load("res://scenes/town/town.tscn").instantiate()
	get_tree().root.add_child(town)
	await _frames(5)

	# --- 场景基本件 ---
	var player: PlayerCharacter = town.get_node_or_null("World/Player")
	_check(player != null, "玩家存在")
	var npcs: Node = town.find_child("NPC_陈婆", true, false)
	_check(npcs != null, "陈婆存在")
	var boar_count := 0
	for c in town.find_children("*", "Boar", true, false):
		boar_count += 1
	_check(boar_count == 3, "野猪x3（实际 %d）" % boar_count)

	# --- 对话链：初见（给糖+饼干）---
	npcs.interact(player)
	await _drive_dialogue()
	_check(Game.state == Game.State.PLAYING, "对话结束后回到PLAYING")
	_check(Inventory.count("candy") == 2, "初见给糖x2（实际 %d）" % Inventory.count("candy"))
	_check(Inventory.count("biscuit") == 2, "初见给饼干x2（实际 %d）" % Inventory.count("biscuit"))
	_check(Game.get_flag("met_chenpo") != null, "flag met_chenpo 已置位")

	# --- 对话链：重访（走 repeat 分支，不再给糖）---
	npcs.interact(player)
	await _drive_dialogue()
	_check(Inventory.count("candy") == 2, "重访不再给糖（实际 %d）" % Inventory.count("candy"))

	# --- 老校长事件对话：阿豆跑过来 + 解锁火山口 ---
	var teacher: Node = town.find_child("NPC_老校长", true, false)
	_check(teacher != null, "老校长存在")
	var adou: Node2D = town.find_child("NPC_阿豆", true, false)
	_check(adou != null, "阿豆存在")
	teacher.interact(player)
	await _drive_dialogue()
	_check(Game.get_flag("allowed_up_mountain") == null, "老校长对话后火山口仍锁（正典：爆发后才开）")
	await _frames(40)
	_check(adou.global_position.distance_to((teacher as Node2D).global_position) < 80.0,
		"演出：阿豆跑到了老校长身边（距离 %.0fpx）" % adou.global_position.distance_to((teacher as Node2D).global_position))

	# --- 战斗：受伤/无敌帧/回血 ---
	var hp0 := player.hp
	player.take_damage(5, player.global_position + Vector2(10, 0))
	_check(player.hp == hp0 - 5, "受伤扣5（实际 %d）" % player.hp)
	player.take_damage(5, player.global_position)
	_check(player.hp == hp0 - 5, "无敌帧内不重复扣血")
	await _frames(70)
	player.heal(20)
	_check(player.hp == player.max_hp, "回血到满")

	# --- 战斗：击杀野猪 → 掉石子 → 玩家走过去捡 ---
	var stones_before := Inventory.count("stone")
	var dead_boar_pos := Vector2.ZERO
	for c in town.find_children("*", "Boar", true, false):
		dead_boar_pos = c.global_position
		c.take_hit(10, c.global_position + Vector2(20, 0))
		break
	await _frames(5)
	player.global_position = dead_boar_pos  # 走到掉落物上
	await _frames(10)
	_check(Inventory.count("stone") == stones_before + 2, "野猪死亡掉石子x2并拾取（+%d）" % (Inventory.count("stone") - stones_before))

	# --- 存档 ---
	SaveSystem.save_slot(1)
	_check(SaveSystem.has_slot(1), "存档槽1已写入")

	# --- 弹弓 ---
	Inventory.add_item("stone", 5)
	StoneProjectile.spawn(get_tree(), player.global_position, Vector2.RIGHT)
	await _frames(3)
	var found_projectile := get_tree().root.find_children("*", "StoneProjectile", true, false).size() > 0
	_check(found_projectile, "弹弓石子生成")

	# --- 世界地图：地点闸门 ---
	var world: Node = load("res://scenes/world/worldmap.tscn").instantiate()
	get_tree().root.add_child(world)
	await _frames(3)
	var gates := world.find_children("*", "LocationGate", true, false)
	_check(gates.size() == 3, "世界地图地点x3（实际 %d）" % gates.size())
	var crater: LocationGate = null
	var forest: LocationGate = null
	for g in gates:
		if g.name == "Loc_火山口":
			crater = g
		elif g.name == "Loc_东林子":
			forest = g
	_check(crater != null and crater.target_scene.contains("mountain_road"), "火山口闸门指向山道场景")
	var notify_count := [0]
	var notify_handler := func(_t): notify_count[0] += 1
	Events.notify.connect(notify_handler)
	# 永锁的东林子：触发只弹提示，绝不切场景
	forest._on_body_entered(player)
	await _frames(2)
	_check(notify_count[0] == 1, "锁门地点触发时给出提示且不切场景")
	# 火山口：数据断言（不真触发，避免切场景）；解锁 flag 由爆发晨段置位
	_check(crater.unlock_flag == "allowed_up_mountain", "火山口由 allowed_up_mountain flag 把门")
	Events.notify.disconnect(notify_handler)
	world.queue_free()
	await _frames(2)

	# --- M2：上山之路 / 办公区门禁 / 空镇揭示 ---
	print("[trace] M2开始, current_scene=", get_tree().current_scene.name)
	var mountain: Node = load("res://scenes/mountain/mountain_road.tscn").instantiate()
	get_tree().root.add_child(mountain)
	await _frames(3)
	print("[trace] 山道已载入, in_tree=", is_inside_tree())
	var m_boars := 0
	var m_birds := 0
	for c in mountain.find_children("*", "Boar", true, false):
		m_boars += 1
	for c in mountain.find_children("*", "FlyingBird", true, false):
		m_birds += 1
	_check(m_boars == 3, "山道野猪x3（实际 %d）" % m_boars)
	_check(m_birds == 2, "山道低飞鸟x2（实际 %d）" % m_birds)
	_check(mountain.find_child("AshFall", true, false) != null, "山道：灰烬粒子在场（越近山口越浓）")
	mountain.queue_free()
	await _frames(2)
	print("[trace] 山道已卸载, in_tree=", is_inside_tree(), " scene=", get_tree().current_scene.name if get_tree() != null else "无tree")

	var office: Node = load("res://scenes/office/office.tscn").instantiate()
	get_tree().root.add_child(office)
	await _frames(3)
	var doors := office.find_children("Door_*", "StaticBody2D", true, false)
	_check(doors.size() == 3, "办公区门禁x3（实际 %d）" % doors.size())
	Game.set_flag("password_found", true)
	Game.set_flag("doors_open", true)
	await _frames(5)
	var doors_after := office.find_children("Door_*", "StaticBody2D", true, false)
	_check(doors_after.size() == 0, "输入密码后门禁消失")
	_check(office.find_child("Prop_红门", true, false) != null, "红门存在（封存）")
	office.queue_free()
	await _frames(2)

	var reveal: Node = load("res://scenes/town/town_reveal.tscn").instantiate()
	get_tree().root.add_child(reveal)
	await _frames(3)
	var points := 0
	for n in ["Prop_街心", "Prop_小卖部", "Prop_六叔的船", "Prop_老校长家", "Prop_坟头", "Prop_镇公所", "Prop_床底洞"]:
		if reveal.find_child(n, true, false) != null:
			points += 1
	_check(points == 7, "空镇检视点x7（实际 %d）" % points)
	_check(reveal.find_child("NPC_陈婆", true, false) == null, "空镇没有NPC")
	_check(reveal.find_child("IntroZone_out_1", true, false) == null, "空镇没有开场独白触发区")
	reveal.queue_free()
	await _frames(2)

	# --- T1：小镇开场落点 / 独白触发区 ---
	_check(town.find_child("FromHome", true, false) != null, "小镇：FromHome 落点标记存在")
	var zone_count := town.find_children("*", "StoryZone", true, false).size()
	_check(zone_count == 3, "小镇：开场独白触发区x3（实际 %d）" % zone_count)
	var from_home := town.find_child("FromHome", true, false) as Marker2D
	_check(from_home != null and from_home.global_position.distance_to(Vector2(240, 524.8)) < 4.0,
		"小镇：FromHome 在我家门口（%s）" % str(from_home.global_position if from_home else Vector2.ZERO))

	# --- T1：intro 对话资源与标题 ---
	var intro: DialogueResource = load("res://resources/dialogue/town/intro.dialogue")
	_check(intro != null, "intro 对话资源存在")
	if intro != null:
		var cues: PackedStringArray = intro.get_cues()
		for t in ["wake_call", "out_1", "out_2", "out_3"]:
			_check(t in cues, "intro 对话含标题 %s" % t)

	# --- M3：全人物对话 + 结局场景 ---
	var dialogue_paths := [
		"res://resources/dialogue/town/liushu.dialogue",
		"res://resources/dialogue/town/alan.dialogue",
		"res://resources/dialogue/town/adou.dialogue",
		"res://resources/dialogue/town/dani.dialogue",
		"res://resources/dialogue/town/eruption.dialogue",
		"res://resources/dialogue/ending/ending_silence.dialogue",
		"res://resources/dialogue/ending/ending_reply.dialogue",
	]
	for p in dialogue_paths:
		_check(load(p) != null, "对话资源存在：%s" % p.get_file())
	var ash_scene: PackedScene = load("res://scenes/fx/ash_fall.tscn")
	_check(ash_scene != null, "灰烬粒子场景可加载")
	if ash_scene != null:
		var ash: AshFall = ash_scene.instantiate()
		ash.density = 10
		get_tree().root.add_child(ash)
		await _frames(2)
		_check(ash.amount == 10 and ash.emitting, "灰烬粒子：density→amount 联动且已发射")
		ash.queue_free()
		await _frames(1)
	_check(town.find_child("NPC_六叔", true, false) != null, "小镇：六叔在码头")
	_check(town.find_child("NPC_阿蓝", true, false) != null, "小镇：阿蓝在会堂钢琴边")
	_check(town.find_child("Prop_钢琴", true, false) != null, "小镇：会堂钢琴存在")

	# 结局场景只验构件（auto_play=false 防真触发演出/切场景——坑#12）
	var sil: Node = load("res://scenes/ending/ending_silence.tscn").instantiate()
	sil.auto_play = false
	get_tree().root.add_child(sil)
	await _frames(3)
	_check(sil.find_child("Marker_树", true, false) != null, "结局一：镇口第二棵树标记")
	_check(sil.find_child("Marker_钢琴", true, false) != null, "结局一：钢琴前标记")
	_check(sil.find_child("Alan", true, false) != null, "结局一：阿蓝在场")
	_check(sil.find_child("Piano", true, false) != null, "结局一：钢琴在场")
	sil.queue_free()
	await _frames(2)

	var rep: Node = load("res://scenes/ending/ending_reply.tscn").instantiate()
	rep.auto_play = false
	get_tree().root.add_child(rep)
	await _frames(3)
	_check(rep.find_child("Marker_少校", true, false) != null, "结局二：少校标记")
	_check(rep.find_child("Marker_跳板", true, false) != null, "结局二：跳板标记")
	var major: Node = rep.find_child("Major", true, false)
	_check(major != null and major.ghost == false, "结局二：少校是实体人物（ghost=false）")
	_check(rep.find_child("Ship", true, false) != null, "结局二：海上船影")
	rep.queue_free()
	await _frames(2)

	var roll_scene: PackedScene = load("res://scenes/ending/staff_roll.tscn")
	_check(roll_scene != null, "结局：staff roll 场景可加载")
	if roll_scene != null:
		var roll: Node = roll_scene.instantiate()
		get_tree().root.add_child(roll)
		await _frames(2)
		var labels := roll.find_children("*", "Label", true, false)
		_check(labels.size() > 0 and "最后离开的我" in labels[0].text, "结局：staff roll 名单文本在场景里（可编辑）")
		roll.free()
		await _frames(2)

	# --- T1：我家室内（装载 + 呼唤演出链 + 起身后回 PLAYING）---
	var home: Node = load("res://scenes/town/home_interior.tscn").instantiate()
	get_tree().root.add_child(home)
	await _frames(3)
	_check(home.find_child("Player", true, false) != null, "室内：玩家存在")
	_check(home.find_child("DoorZone", true, false) != null, "室内：出门区存在")
	_check(home.find_child("Furn_bed", true, false) != null, "室内：床存在")
	_check(home.find_child("Prop_床", true, false) != null, "室内：床检视点（睡下）存在")
	_check(home.find_child("Furn_cabinet", true, false) != null, "室内：立柜存在")
	_check(home.find_child("Deco_window", true, false) != null, "室内：窗存在")
	# _ready 自动播黑屏呼唤 → 驱动到结束 → 等起身演出跑完（淡入+起身≈1.7s，墙钟预算）
	await _drive_dialogue()
	var woke := false
	var wake_deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < wake_deadline:
		await get_tree().process_frame
		if Game.state == Game.State.PLAYING and Game.get_flag("intro_wake_done") != null:
			woke = true
			break
	_check(woke, "室内：呼唤+起身演完回 PLAYING 且 intro_wake_done 置位")

	# --- 序章·火山爆发：置 sleep_requested → home_root 接管演出 → 晨段解锁火山口 ---
	Game.set_flag("sleep_requested", true)
	var boom_deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < boom_deadline and Game.get_flag("eruption_done") == null:
		await _drive_dialogue()
		await _frames(5)
	_check(Game.get_flag("eruption_seen") != null, "爆发演出：eruption_seen 置位")
	_check(Game.get_flag("eruption_done") != null, "爆发演出：晨段完成（eruption_done）")
	_check(Game.get_flag("allowed_up_mountain") != null, "爆发后火山口解锁（allowed_up_mountain）")
	var settle := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < settle and Game.state != Game.State.PLAYING:
		await get_tree().process_frame

	# --- 爆发后小镇视觉（数据断言，不切场景）---
	var town2: Node = load("res://scenes/town/town.tscn").instantiate()
	get_tree().root.add_child(town2)
	await _frames(3)
	_check(town2.find_child("AshSky", true, false) != null, "爆发后小镇：灰天在场")
	_check(town2.find_child("AshFall", true, false) != null, "爆发后小镇：黑雪跟随玩家")
	town2.queue_free()
	await _frames(2)
	home.queue_free()
	await _frames(2)

	if failures.is_empty():
		print("M1 SMOKE PASS")
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL: ", f)
		print("M1 SMOKE FAIL")
		get_tree().quit(1)


func _check(cond: bool, label: String) -> void:
	if not cond:
		failures.append(label)
	else:
		print("ok - ", label)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## 驱动当前对话直到结束：逐行推进，选项取第一项。
## 用墙钟预算而非帧数——突变演出（NPC走位/等待）按物理与真实时间跑，
## 无头模式帧率会漂，帧数窗口会把正常演出误判成卡死（T1 轮实测教训）。
## 同一行只发一次推进：跳字 → 等 is_waiting → next；突变期间不堆 next。
func _drive_dialogue() -> void:
	var deadline := Time.get_ticks_msec() + 30000
	var sent_for: Object = null  # 已对哪一行发过推进（DialogueLine 每行都是新对象）
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		var balloon = get_tree().root.find_child("DialogueBalloon", true, false)
		if balloon == null or not is_instance_valid(balloon):
			return
		var line = balloon.dialogue_line
		if line == null:
			await _frames(3)
			return
		if balloon.dialogue_label.is_typing:
			balloon.dialogue_label.skip_typing()
			continue
		if sent_for == line:
			continue  # 推进已发：等突变跑完/下一行到来
		sent_for = line
		if line.responses.size() > 0:
			balloon.next(line.responses[0].next_id)
		else:
			balloon.next(line.next_id)
	failures.append("对话未在30秒内结束")
