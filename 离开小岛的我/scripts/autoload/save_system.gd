extends Node
## JSON 存档：3 个手动槽 + 1 个自动槽。
## M0 先只存全局 flag 与所在场景；M1 起并入玩家状态（HP/位置/背篓）。

const SAVE_DIR := "user://saves/"
const SLOT_COUNT := 3
const AUTO_SLOT := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_slot(slot: int) -> bool:
	var data := {
		"version": 1,
		"saved_at": Time.get_datetime_string_from_system(),
		"scene": Game.current_scene_path,
		"flags": Game.flags,
		# M1 追加: "player": {hp, position, items}
	}
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(SAVE_DIR + "slot_%d.json" % slot, FileAccess.WRITE)
	if file == null:
		push_error("存档失败: slot_%d (%s)" % [slot, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	Events.notify.emit("已存档 · 槽位%d" % slot)
	return true


func load_slot(slot: int) -> Dictionary:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "slot_%d.json" % slot)


## 读档并回到存档时的场景（M0 简化版：只恢复 flags，不搬运玩家）。
func apply_slot(slot: int) -> bool:
	var data := load_slot(slot)
	if data.is_empty():
		return false
	Game.flags = data.get("flags", {})
	var scene: String = data.get("scene", "")
	if scene != "" and scene != Game.current_scene_path:
		Game.change_scene(scene)
	return true
