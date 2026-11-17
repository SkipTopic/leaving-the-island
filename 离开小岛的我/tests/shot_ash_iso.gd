extends Node
## AshFall 隔离渲染实验：纯色背景 + 粒子节点，拍一张看它到底画不画。

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	var bg := ColorRect.new()
	bg.color = Color(0.3, 0.55, 0.3)
	bg.size = Vector2(640, 360)
	add_child(bg)

	var ash: AshFall = preload("res://scenes/fx/ash_fall.tscn").instantiate()
	ash.name = "AshFall"
	ash.position = Vector2(320, -60)
	ash.density = 40.0
	add_child(ash)
	await get_tree().process_frame
	print("[iso] emitting=", ash.emitting, " amount=", ash.amount,
		" visibility_rect=", ash.visibility_rect, " pos=", ash.global_position)
	for i in 180:
		await get_tree().process_frame
	print("[iso] 3s后 visibility_rect=", ash.visibility_rect)
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://").path_join("../Zcode工作区域/00_思考过程/M4_粒子隔离实验.png"))
	print("已存隔离实验图")
	get_tree().quit(0)
