extends Node2D
## M0 占位房间：Esc 回标题，验证反向转场；进入时打一条存档自检日志。

const TITLE_SCENE := "res://scenes/main/main.tscn"


func _ready() -> void:
	Game.state = Game.State.PLAYING
	print("[M0] 进入占位房间，场景切换链路 OK")
	# 存档系统自检：写自动档再读回，验证 FileAccess 与 JSON 链路
	SaveSystem.save_slot(SaveSystem.AUTO_SLOT)
	var data := SaveSystem.load_slot(SaveSystem.AUTO_SLOT)
	print("[M0] 存档自检: scene=%s flags=%s" % [data.get("scene", "?"), data.get("flags", {})])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Game.change_scene(TITLE_SCENE)
