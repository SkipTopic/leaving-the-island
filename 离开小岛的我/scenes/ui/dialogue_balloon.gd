extends CanvasLayer
## 像素风中文对话气球（Dialogue Manager 4 专用）。
## 结构沿用官方 example_balloon：Balloon 接 gui_input 推进，ResponsesMenu 出选项。

@export var next_action: StringName = &"interact"
@export var skip_action: StringName = &"interact"

@export_group("对话显示（用户可调）")
## 字号。点阵字体在 12 的整数倍最锐利：12（原版）/ 24（特大）；16、20 会有轻微虚边
@export_range(8, 48, 1) var font_size := 12
## 行间距（行与行之间额外加的像素，0=紧凑）
@export_range(0, 16, 1) var line_separation := 2
## 对话面板总高度（px，从屏幕底往上量）。字号调大后记得跟着调大，否则文字挤出面板
@export_range(80, 320, 1) var panel_height := 132.0

var resource: DialogueResource
var temporary_game_states: Array = []
var is_waiting_for_input := false
var will_hide_balloon := false

var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			_apply_dialogue_line()
		else:
			queue_free()
	get:
		return dialogue_line

var mutation_cooldown := Timer.new()

@onready var balloon: Control = %Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: RichTextLabel = %DialogueLabel
@onready var responses_menu: VBoxContainer = %ResponsesMenu
@onready var progress_label: Label = %ProgressLabel


func _ready() -> void:
	balloon.hide()
	balloon.theme = UiKit.pixel_theme(font_size)
	var panel: PanelContainer = %Panel
	panel.add_theme_stylebox_override("panel", UiKit.panel_style())
	# 面板高度/行距：检查器"对话显示"组可调（tscn 里的固定偏移在这里覆盖）
	var margin: MarginContainer = balloon.get_node("Margin")
	margin.offset_top = -panel_height
	for lbl in [character_label, dialogue_label]:
		lbl.add_theme_font_size_override("normal_font_size", font_size)
		lbl.add_theme_font_size_override("bold_font_size", font_size)
		lbl.add_theme_font_size_override("italics_font_size", font_size)
		lbl.add_theme_font_size_override("mono_font_size", font_size)
		lbl.add_theme_constant_override("line_separation", line_separation)
	var template := responses_menu.get_node_or_null("ResponseExample") as Button
	if template != null:
		for style_name in UiKit.button_styles():
			template.add_theme_stylebox_override(style_name, UiKit.button_styles()[style_name])

	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	responses_menu.next_action = next_action
	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)


func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress_label.visible = is_waiting_for_input \
			and not dialogue_label.is_typing \
			and dialogue_line.responses.size() == 0


func _unhandled_input(_event: InputEvent) -> void:
	# 对话期间独占输入
	get_viewport().set_input_as_handled()


func start(with_resource: DialogueResource = null, title := "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_resource):
		resource = with_resource
	dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)
	show()


func _apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	progress_label.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = dialogue_line.character

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
		responses_menu.focus_first_item()
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


func next(next_id: String) -> void:
	dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# 鼠标左键点按/触摸点按 = 推进·跳过（手机点屏、桌面点击都走这里；
	# 只认 MouseButton：PC 的 emulate_touch_from_mouse 会把一次点击同时
	# 生成鼠标+触摸两种事件，两个都认会一笔点两下）
	var tapped: bool = event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT and event.pressed

	if dialogue_label.is_typing:
		if event.is_action_pressed(skip_action) or tapped:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input:
		return
	if dialogue_line.responses.size() > 0:
		return

	get_viewport().set_input_as_handled()
	if event.is_action_pressed(next_action) or tapped:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)
