class_name LocationGate
extends Area2D
## 世界地图的地点闸门：走进去 → 开放则切换场景；锁着则提示。
## 全部参数在检查器里配（目标场景/落点/解锁flag/文案）。

## 地点名（显示用）
@export var display_name := "？？？"
## 目标场景（res:// 路径）。留空 = 场景还没做，用 unlocked_text 提示
@export var target_scene := ""
## 到达目标场景后的落点 Marker2D 名
@export var spawn_point_name := ""
## 需要的剧情标记（空=始终开放）
@export var unlock_flag := ""
## 锁着时的提示
@export var locked_text := "现在还过不去。"
## 开放但场景未做时的提示
@export var unlocked_text := "（这一带还没修好）"
## 提示冷却（秒），防止连发
@export_range(0.2, 5.0) var notify_cooldown := 1.2

var _cool := 0.0
var _busy := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4  # 玩家
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)


func _on_body_entered(body: Node2D) -> void:
	if _busy or _cool > 0.0 or not body.is_in_group("player"):
		return
	if unlock_flag != "" and Game.get_flag(unlock_flag) == null and not Game.god_mode:
		_cool = notify_cooldown
		Events.notify.emit(locked_text)
		return
	if target_scene == "":
		_cool = notify_cooldown
		Events.notify.emit(unlocked_text)
		return
	_busy = true
	Game.pending_spawn = spawn_point_name
	Game.change_scene(target_scene)
