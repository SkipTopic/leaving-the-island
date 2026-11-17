extends Node
## 全局状态机 + 场景切换（自带黑屏转场层）。
## flags 是剧情进度的唯一权威数据源，存档只打包它和玩家状态。

enum State { BOOT, TITLE, PLAYING, DIALOGUE, BACKPACK, CUTSCENE, ENDING }

const FADE_TIME := 0.35

const FADE_SHADER := """
shader_type canvas_item;
uniform float alpha : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""

var state: State = State.BOOT
var flags: Dictionary = {}
var current_scene_path := ""
## 场景切换前的落点标记名：切换后由场景根脚本把玩家放到同名 Marker2D 上。
var pending_spawn := ""
## 上帝模式（调试用）：P键/HUD按钮切换。全闸门开放、玩家无敌、剧情触发区禁用、补调试物资。
## 会话级（不入存档），重启默认关闭。
var god_mode := false

var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_transition_layer()
	var cur := get_tree().current_scene
	current_scene_path = cur.scene_file_path if cur else ""
	state = State.TITLE


func set_flag(flag: String, value: Variant) -> void:
	flags[flag] = value
	Events.story_flag_changed.emit(flag, value)


## 上帝模式切换（HUD 按钮 / P 键都会走到这）。
func toggle_god_mode() -> void:
	god_mode = not god_mode
	print("[Game] 上帝模式 → ", "开" if god_mode else "关")
	if god_mode:
		# 调试物资：石子/火柴管够（隧道黑暗机制要火柴），饼干回血
		Inventory.add_item("stone", 99)
		Inventory.add_item("match", 99)
		Inventory.add_item("biscuit", 9)
		Events.notify.emit("上帝模式 开：全闸门开放、无敌、物资已补。")
	else:
		Events.notify.emit("上帝模式 关。")


func get_flag(flag: String, default: Variant = null) -> Variant:
	return flags.get(flag, default)


## 带转场的场景切换：黑入 -> 换场景 -> 黑出。
func change_scene(path: String) -> void:
	if _busy:
		return
	print("[Game] change_scene → %s (来自 %s)" % [path, get_stack()[1] if get_stack().size() > 1 else "?"])
	_busy = true
	var tw := create_tween()
	tw.tween_method(_set_fade_alpha, 0.0, 1.0, FADE_TIME)
	await tw.finished
	Events.scene_change_started.emit(path)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	current_scene_path = path
	Events.scene_change_finished.emit(path)
	var tw2 := create_tween()
	tw2.tween_method(_set_fade_alpha, 1.0, 0.0, FADE_TIME)
	await tw2.finished
	_busy = false


func _set_fade_alpha(a: float) -> void:
	_mat.set_shader_parameter("alpha", a)


func _build_transition_layer() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = FADE_SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("alpha", 0.0)
	_rect.material = _mat
	_layer.add_child(_rect)
