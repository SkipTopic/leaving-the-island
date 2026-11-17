extends Node
## 导出 Ground 层的源ID分布图（诊断草地噪声分布形状用）。运行时场景版（需要 autoloads）。
## 运行: godot --headless --path <工程> res://tests/dump_ground.tscn

const COLORS := {
	0: Color(0.4, 0.75, 0.3),
	1: Color(0.75, 0.6, 0.4),
	2: Color(0.2, 0.4, 0.8),
	3: Color(1, 1, 0.4),
	4: Color(0.8, 0.4, 0.2),
	5: Color(0.5, 0.8, 1),
	6: Color(0.1, 0.35, 0.1),
	7: Color(0.9, 1.0, 0.75),
	8: Color(0.55, 0.6, 0.2),
	9: Color(0.3, 0.27, 0.24),
	10: Color(0.95, 0.95, 0.9),
	11: Color(0.95, 0.95, 0.9),
	12: Color(0.95, 0.95, 0.9),
}
const JOBS := [
	["res://scenes/world/worldmap.tscn", "res://../Zcode工作区域/00_思考过程/诊断_世界地图草地分布.png"],
	["res://scenes/town/town.tscn", "res://../Zcode工作区域/00_思考过程/诊断_小镇草地分布.png"],
	["res://scenes/mountain/mountain_road.tscn", "res://../Zcode工作区域/00_思考过程/诊断_山道公路俯视.png"],
]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for job in JOBS:
		var scene: Node = (load(job[0]) as PackedScene).instantiate()
		get_tree().root.add_child(scene)
		await get_tree().process_frame
		var ground: TileMapLayer = scene.get_node("Ground")
		var used := ground.get_used_cells()
		var mn := Vector2i(999999, 999999)
		var mx := Vector2i(-999999, -999999)
		for c in used:
			mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
			mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
		var img := Image.create(mx.x - mn.x + 1, mx.y - mn.y + 1, false, Image.FORMAT_RGBA8)
		for c in used:
			var sid := ground.get_cell_source_id(c)
			img.set_pixel(c.x - mn.x, c.y - mn.y, COLORS.get(sid, Color(1, 0, 1)))
		img.resize((mx.x - mn.x + 1) * 8, (mx.y - mn.y + 1) * 8, Image.INTERPOLATE_NEAREST)
		var out := ProjectSettings.globalize_path(job[1])
		var err := img.save_png(out)
		print("[dump] %s %d格 → %s (%s)" % [job[0], used.size(), out.get_file(), "OK" if err == OK else error_string(err)])
		scene.queue_free()
	get_tree().quit(0)
