extends CharacterBody2D
## M0 输入验证用小方块：8 向移动，走通 move_* 输入映射。

const SPEED := 140.0


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
