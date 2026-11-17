shader_type canvas_item;
// 透明镇民：半透明+轻微提亮，玩家"看惯了"的诅咒模样。

uniform float alpha : hint_range(0.0, 1.0) = 0.52;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(c.rgb * vec3(1.06, 1.04, 1.0), c.a * alpha);
}
