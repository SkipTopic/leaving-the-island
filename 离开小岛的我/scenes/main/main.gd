extends Node2D
## 主菜单：点屏幕/任意键开始（T1-a：手机必须支持 InputEventScreenTouch）。

const NEXT_SCENE := "res://scenes/town/home_interior.tscn"  # 开场序列：先回家醒来
const FONT_PATH := "res://assets/fonts/fusion_pixel_12px_monospaced.ttf"

var _starting := false


func _ready() -> void:
	Game.state = Game.State.TITLE
	_apply_pixel_font()


func _unhandled_input(event: InputEvent) -> void:
	if _starting:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		_starting = true
		Game.change_scene(NEXT_SCENE)


func _apply_pixel_font() -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return  # 字体尚未就位时用默认字体，不报错
	var font := load(FONT_PATH) as FontFile
	if font == null:
		return
	for label in get_tree().get_nodes_in_group("use_pixel_font"):
		label.add_theme_font_override("font", font)
