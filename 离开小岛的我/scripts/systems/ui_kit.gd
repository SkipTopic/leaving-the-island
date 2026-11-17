class_name UiKit
## UI 小工具箱：统一像素字体主题、统一面板风格。

const FONT_PATH := "res://assets/fonts/fusion_pixel_12px_monospaced.ttf"


static func pixel_theme(font_size := 12) -> Theme:
	var t := Theme.new()
	if ResourceLoader.exists(FONT_PATH):
		t.default_font = load(FONT_PATH)
	t.default_font_size = font_size
	return t


static func panel_style(bg := Color(0.07, 0.08, 0.13, 0.92), border := Color(0.72, 0.66, 0.5)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func button_styles() -> Dictionary:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.11, 0.17, 0.95)
	normal.border_color = Color(0.45, 0.42, 0.34)
	normal.set_border_width_all(2)
	var focus := normal.duplicate()
	focus.border_color = Color(0.95, 0.85, 0.55)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.06, 0.06, 0.09, 0.9)
	return {"normal": normal, "hover": focus, "focus": focus, "pressed": focus, "disabled": disabled}
