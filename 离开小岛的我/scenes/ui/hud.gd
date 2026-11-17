class_name GameHUD
extends CanvasLayer
## 游戏 HUD：血条 / 物品计数 / 交互提示 / 通知条 / 背篓面板。全部代码构建。

var hp_bar: ProgressBar
var hp_fill_style: StyleBoxFlat
var stone_label: Label
var candy_label: Label
var prompt_label: Label
var notify_label: Label
var backpack_panel: PanelContainer
var backpack_grid: GridContainer
var god_btn: Button

var _notify_tween: Tween
var _god_btn_state := false


func _ready() -> void:
	layer = 50
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.pixel_theme(12)
	add_child(root)

	# --- 左上：血条 ---
	var hp_box := PanelContainer.new()
	hp_box.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.07, 0.08, 0.13, 0.75)))
	hp_box.position = Vector2(8, 8)
	hp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hp_name := Label.new()
	hp_name.text = "HP"
	hp_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_child(hp_name)
	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = 20
	hp_bar.value = 20
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(90, 12)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.16, 0.1, 0.1)
	bg.border_color = Color(0.45, 0.42, 0.34)
	bg.set_border_width_all(1)
	hp_fill_style = StyleBoxFlat.new()
	hp_fill_style.bg_color = Color(0.45, 0.72, 0.34)
	hp_bar.add_theme_stylebox_override("background", bg)
	hp_bar.add_theme_stylebox_override("fill", hp_fill_style)
	hp_row.add_child(hp_bar)
	hp_box.add_child(hp_row)
	root.add_child(hp_box)

	# --- 右上：物品计数 ---（左边留了上帝模式按钮的位置）
	var item_box := PanelContainer.new()
	item_box.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.07, 0.08, 0.13, 0.75)))
	item_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	item_box.position = Vector2(-118, 8)
	item_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var item_row := HBoxContainer.new()
	item_row.add_theme_constant_override("separation", 6)
	item_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stone_row := _make_icon_row("res://assets/sprites/custom/stone.png")
	stone_label = stone_row[1]
	item_row.add_child(stone_row[0])
	var candy_row := _make_icon_row("res://assets/ui/icons_kyrises/candy_01a.png")
	candy_label = candy_row[1]
	item_row.add_child(candy_row[0])
	item_box.add_child(item_row)
	root.add_child(item_box)
	_refresh_counts()

	# --- 底部中间：交互提示 ---
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.anchor_top = 1.0
	prompt_label.anchor_bottom = 1.0
	prompt_label.offset_top = -46.0
	prompt_label.offset_bottom = -30.0
	prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.text = ""
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(prompt_label)

	# --- 通知条 ---
	notify_label = Label.new()
	notify_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	notify_label.anchor_top = 1.0
	notify_label.anchor_bottom = 1.0
	notify_label.offset_top = -68.0
	notify_label.offset_bottom = -50.0
	notify_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	notify_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notify_label.modulate.a = 0.0
	notify_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(notify_label)

	# --- 背篓面板 ---
	_build_backpack(root)

	# --- 右上角：上帝模式按钮（P 键也可切换；调试用）---
	_build_god_button(root)

	Events.player_hp_changed.connect(_on_hp_changed)
	Events.item_picked.connect(func(_id, _n): _refresh_counts())
	Events.prompt_changed.connect(_on_prompt)
	Events.notify.connect(show_notify)

	_build_touch(root)


# ================= 触屏操作（手机摇杆+按钮） =================
# 摇杆驱动的是标准 move_* 动作的强度，键盘/摇杆/手柄天然共用一套玩家代码。

const JOY_RADIUS := 52.0
const JOY_DEADZONE := 0.18
## 手机/桌面都显示（桌面可用鼠标模拟触摸来测试）；想隐藏改 false
const SHOW_TOUCH_UI := true

var _touch_root: Control
var _joy_view: Control
var _joy_index := -1
var _joy_center := Vector2.ZERO
var _knob_view: Control


func _build_touch(root: Control) -> void:
	_touch_root = Control.new()
	_touch_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_root.visible = SHOW_TOUCH_UI
	root.add_child(_touch_root)

	# 摇杆底盘 + 球（自绘圆）
	_joy_view = JoyBaseView.new()
	_joy_view.position = Vector2(34, 360 - 138)
	_joy_view.size = Vector2(JOY_RADIUS * 2 + 8, JOY_RADIUS * 2 + 8)
	_joy_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_root.add_child(_joy_view)
	_knob_view = JoyKnobView.new()
	_knob_view.size = Vector2(44, 44)
	_knob_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_root.add_child(_knob_view)
	_reset_knob()

	# 右下按钮组（菱形排布）：上=弹弓 左=对话 右=攻击 下=背篓
	_add_touch_button(Vector2(640 - 120, 360 - 152), "弹弓", "slingshot", false)
	_add_touch_button(Vector2(640 - 176, 360 - 100), "对话", "interact", true)
	_add_touch_button(Vector2(640 - 64, 360 - 100), "攻击", "attack", false)
	_add_touch_button(Vector2(640 - 120, 360 - 48), "背篓", "backpack", true)


func _add_touch_button(pos: Vector2, label: String, action: String, edge_only: bool) -> void:
	var btn := Button.new()
	btn.text = label
	btn.size = Vector2(52, 52)
	btn.position = pos
	btn.add_theme_font_size_override("font_size", 12)
	btn.focus_mode = Control.FOCUS_NONE
	for style_name in UiKit.button_styles():
		btn.add_theme_stylebox_override(style_name, UiKit.button_styles()[style_name])
	btn.button_down.connect(_on_touch_action.bind(action, edge_only, true))
	btn.button_up.connect(_on_touch_action.bind(action, edge_only, false))
	_touch_root.add_child(btn)


func _on_touch_action(action: String, edge_only: bool, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
		if edge_only:
			# 交互/背篓是"按一下"型：短暂按住后松开，让 is_action_just_pressed 触发
			await get_tree().create_timer(0.06).timeout
			Input.action_release(action)
	else:
		Input.action_release(action)


func _joy_zone() -> Rect2:
	return Rect2(0, 360 - 200, 220, 200)


func _input(event: InputEvent) -> void:
	if _touch_root == null or not _touch_root.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _joy_index == -1 and _joy_zone().has_point(event.position):
			_joy_index = event.index
			_joy_center = _joy_view.position + _joy_view.size / 2.0
			_update_joystick(event.position)
		elif not event.pressed and event.index == _joy_index:
			_joy_index = -1
			_reset_knob()
	elif event is InputEventScreenDrag and event.index == _joy_index:
		_update_joystick(event.position)


func _update_joystick(touch_pos: Vector2) -> void:
	var vec := touch_pos - _joy_center
	var len := vec.length()
	if len > JOY_RADIUS:
		vec = vec / len * JOY_RADIUS
	_knob_view.position = _joy_center + vec - _knob_view.size / 2.0
	var strength := vec / JOY_RADIUS
	if strength.length() < JOY_DEADZONE:
		strength = Vector2.ZERO
	_set_move_actions(strength)


func _reset_knob() -> void:
	if _joy_view != null:
		_joy_center = _joy_view.position + _joy_view.size / 2.0
	if _knob_view != null:
		_knob_view.position = _joy_center - _knob_view.size / 2.0
	_set_move_actions(Vector2.ZERO)


func _set_move_actions(strength: Vector2) -> void:
	if strength == Vector2.ZERO:
		for a in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(a)
		return
	if strength.x < 0:
		Input.action_press("move_left", -strength.x)
		Input.action_release("move_right")
	else:
		Input.action_press("move_right", strength.x)
		Input.action_release("move_left")
	if strength.y < 0:
		Input.action_press("move_up", -strength.y)
		Input.action_release("move_down")
	else:
		Input.action_press("move_down", strength.y)
		Input.action_release("move_up")


class JoyBaseView extends Control:
	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, 54.0, Color(0.05, 0.06, 0.1, 0.42))
		draw_arc(c, 54.0, 0, TAU, 48, Color(0.85, 0.8, 0.65, 0.55), 2.0, true)


class JoyKnobView extends Control:
	func _draw() -> void:
		draw_circle(size / 2.0, 21.0, Color(0.92, 0.88, 0.75, 0.62))
		draw_arc(size / 2.0, 21.0, 0, TAU, 32, Color(0.95, 0.92, 0.8, 0.8), 2.0, true)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("god_mode"):
		Game.toggle_god_mode()
	_update_god_button()
	if Input.is_action_just_pressed("backpack") \
			and (Game.state == Game.State.PLAYING or Game.state == Game.State.BACKPACK):
		_toggle_backpack()
	_update_touch_visibility()


# ================= 上帝模式（调试） =================
## 右上角常驻按钮：显示开/关状态，点击可切换；P 键等效。

func _build_god_button(root: Control) -> void:
	god_btn = Button.new()
	god_btn.name = "GodButton"
	god_btn.text = "上帝 关"
	god_btn.position = Vector2(640 - 200, 8)
	god_btn.size = Vector2(74, 30)
	god_btn.add_theme_font_size_override("font_size", 12)
	god_btn.focus_mode = Control.FOCUS_NONE
	god_btn.pressed.connect(Game.toggle_god_mode)
	root.add_child(god_btn)
	_update_god_button()


func _update_god_button() -> void:
	if god_btn == null or Game.god_mode == _god_btn_state:
		return
	_god_btn_state = Game.god_mode
	god_btn.text = "上帝 开" if Game.god_mode else "上帝 关"
	if Game.god_mode:
		var on := UiKit.button_styles()["focus"].duplicate() as StyleBoxFlat
		on.border_color = Color(0.42, 0.85, 0.42)
		for s in ["normal", "hover", "focus", "pressed"]:
			god_btn.add_theme_stylebox_override(s, on)
	else:
		for s in UiKit.button_styles():
			god_btn.add_theme_stylebox_override(s, UiKit.button_styles()[s])


## T1-d：对话/演出期间藏起摇杆和按钮（手机窄屏不遮挡、不误触）。
## 藏的瞬间强制松开摇杆——防止对话弹出那刻还按着方向键，"卡键"走个不停。
func _update_touch_visibility() -> void:
	if _touch_root == null:
		return
	var want := SHOW_TOUCH_UI \
		and (Game.state == Game.State.PLAYING or Game.state == Game.State.BACKPACK)
	if _touch_root.visible == want:
		return
	if not want and _joy_index != -1:
		_joy_index = -1
		_reset_knob()
	_touch_root.visible = want


func _make_icon_row(icon_path: String) -> Array:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return [box, label]


func _refresh_counts() -> void:
	if stone_label != null:
		stone_label.text = "x%d" % Inventory.count("stone")
	if candy_label != null:
		candy_label.text = "x%d" % Inventory.count("candy")


func _on_hp_changed(current: int, max_value: int) -> void:
	hp_bar.max_value = max_value
	hp_bar.value = current
	var ratio := float(current) / float(max_value)
	if ratio > 0.6:
		hp_fill_style.bg_color = Color(0.45, 0.72, 0.34)
	elif ratio > 0.3:
		hp_fill_style.bg_color = Color(0.85, 0.68, 0.25)
	else:
		hp_fill_style.bg_color = Color(0.78, 0.3, 0.24)


func _on_prompt(text: String) -> void:
	prompt_label.text = ("E · " + text) if text != "" else ""


func show_notify(text: String) -> void:
	notify_label.text = text
	if _notify_tween != null and _notify_tween.is_valid():
		_notify_tween.kill()
	notify_label.modulate.a = 0.0
	_notify_tween = create_tween()
	_notify_tween.tween_property(notify_label, "modulate:a", 1.0, 0.15)
	_notify_tween.tween_interval(2.2)
	_notify_tween.tween_property(notify_label, "modulate:a", 0.0, 0.5)


# ---------------- 背篓 ----------------

func _build_backpack(root: Control) -> void:
	backpack_panel = PanelContainer.new()
	backpack_panel.add_theme_stylebox_override("panel", UiKit.panel_style())
	backpack_panel.set_anchors_preset(Control.PRESET_CENTER)
	backpack_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	backpack_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	backpack_panel.visible = false
	var vbox := VBoxContainer.new()
	var title := Label.new()
	title.text = "背 篓"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	backpack_grid = GridContainer.new()
	backpack_grid.columns = 4
	backpack_grid.add_theme_constant_override("h_separation", 4)
	backpack_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(backpack_grid)
	var hint := Label.new()
	hint.text = "点道具使用 · Tab/I 关上"
	hint.modulate = Color(1, 1, 1, 0.55)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)
	backpack_panel.add_child(vbox)
	root.add_child(backpack_panel)


func _toggle_backpack() -> void:
	var opening := not backpack_panel.visible
	backpack_panel.visible = opening
	Game.state = Game.State.BACKPACK if opening else Game.State.PLAYING
	Events.backpack_toggled.emit(opening)
	if opening:
		_refresh_backpack()


func _refresh_backpack() -> void:
	for c in backpack_grid.get_children():
		c.queue_free()
	var ids := Inventory.all().keys()
	ids.sort()
	for id in ids:
		var count: int = Inventory.count(id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(44, 44)
		btn.tooltip_text = "%s\n%s" % [ItemDB.display_name(id), ItemDB.get_item(id)["desc"]]
		btn.icon = load(ItemDB.get_item(id)["icon"]) if ResourceLoader.exists(ItemDB.get_item(id)["icon"]) else null
		btn.text = "x%d" % count if count > 1 else ""
		btn.expand_icon = false
		btn.pressed.connect(_on_item_pressed.bind(id))
		backpack_grid.add_child(btn)
	for i in maxi(0, 8 - ids.size()):
		var empty := Button.new()
		empty.custom_minimum_size = Vector2(44, 44)
		empty.disabled = true
		backpack_grid.add_child(empty)


func _on_item_pressed(id: String) -> void:
	var heal: int = ItemDB.get_item(id)["heal"]
	if heal <= 0:
		Events.notify.emit("%s现在用不上。" % ItemDB.display_name(id))
		return
	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if player == null:
		return
	if player.hp >= player.max_hp:
		Events.notify.emit("现在是满血，舍不得吃。")
		return
	Inventory.remove_item(id)
	player.heal(heal)
	Events.notify.emit("吃掉了%s，回了%d点血。" % [ItemDB.display_name(id), heal])
	_refresh_backpack()
