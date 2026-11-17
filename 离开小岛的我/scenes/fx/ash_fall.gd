class_name AshFall
extends CPUParticles2D
## 灰烬/黑雪下落粒子（爆发后的山道/小镇/空镇共用）。
## 惯例：作为玩家的子节点挂在头顶（position=(0,-230)），全局坐标下落，
## 玩家走到哪灰就下到哪；所有参数检查器可调。

@export_group("粒子")
## 每秒生成数（越大越浓）
@export_range(4.0, 200.0) var density := 24.0:
	set(value):
		density = value
		amount = int(value)
## 雪片颜色（黑雪偏黑、灰烬偏暖灰；贴图本身是白色）
@export var flake_color := Color(0.16, 0.13, 0.14, 0.9):
	set(value):
		flake_color = value
		color = value
## 横向漂移（正=向东，负=向西）
@export_range(-60.0, 60.0) var wind := 14.0:
	set(value):
		wind = value
		gravity = Vector2(value, 0)
## 覆盖宽度（像素），要 ≥ 视口宽 640
@export_range(320.0, 2000.0) var width := 960.0:
	set(value):
		width = value
		emission_rect_extents = Vector2(value / 2.0, 8)
## 贴图（默认灰烬点；黑雪用 ash_flake.png）
@export var flake_texture: Texture2D


func _ready() -> void:
	if flake_texture == null:
		flake_texture = preload("res://assets/sprites/custom/ash_speck.png")
	texture = flake_texture
	amount = int(density)
	lifetime = 8.0
	preprocess = 6.0  # 进场景时半空已经有灰，不用等它飘下来
	emission_shape = EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(width / 2.0, 8)
	direction = Vector2(0, 1)
	spread = 10.0
	gravity = Vector2(wind, 0)
	initial_velocity_min = 30.0
	initial_velocity_max = 55.0
	angular_velocity_min = -70.0
	angular_velocity_max = 70.0
	scale_amount_min = 0.7
	scale_amount_max = 1.6
	color = flake_color
	emitting = true  # tscn 里预置 false，参数配好后再开（避免以默认参数喷一帧）
