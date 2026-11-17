extends CanvasLayer
## 结局 Staff Roll：滚动字幕。
## 名单文本就在检查器的 roll_text 里直接改（多行，一行一条）；
## 点击屏幕/按任意键跳过；滚完自动回标题。

## 滚动全程秒数
@export_range(15.0, 120.0) var roll_seconds := 36.0
## 名单文本（检查器里可改；建议用全角空格排版）
@export_multiline var roll_text := """《最后离开的我》



—— 谢谢你玩到这里 ——



【在场的人】
镇长（白天）
晚上的人
陈婆 · 六叔 · 老校长 · 阿豆 · 阿蓝
扫地的婶子 · 狗子
外婆

【这个岛】
莫尼点 · 一座罗盘会打转的岛
三十六个登船的名字
一个留守的名字

【依据】
「离开的我」八章稿（16年版）
「离开的我」长篇小说 · 四结局定稿（30年版）
「孤独之岛」日记（2023原型）

【素材致谢】
Pipoya · Tiny RPG · Pixel Art Top Down Basic
TILESET VILLAGE TOP DOWN · Kyrises 16x16 Icons
Dialogue Manager (nathanhoad)
Godot Engine 4.7

谢谢你，替我们守了这座岛一阵子。
"""

const TITLE_SCENE := "res://scenes/main/main.tscn"

var _content: Label
var _done := false


func _ready() -> void:
	layer = 96
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var clip := Control.new()
	clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)

	_content = Label.new()
	_content.text = roll_text
	_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.custom_minimum_size = Vector2(640, 0)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_content)
	# 从屏幕下方一屏处开始，滚到内容顶出屏幕
	_content.position = Vector2(0, 360)
	_content.reset_size()
	var travel := _content.size.y + 360.0
	var tw := create_tween()
	tw.tween_property(_content, "position:y", -_content.size.y, roll_seconds)
	tw.tween_callback(_finish)


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	# 清掉结局标记：回标题再开新一局时不会被旧 flag 又传进结局
	Game.set_flag("ending", null)
	Game.change_scene(TITLE_SCENE)
