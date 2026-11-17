@tool
class_name SignPost
extends StaticBody2D
## 木牌：可读的交互物。文字在检查器里改。

## 木牌文字（交互时显示）
@export var sign_text := "……"
## 交互提示语
@export var prompt := "读木牌"

@onready var sprite: Sprite2D = $Sprite


func prompt_text() -> String:
	return prompt


func interact(_player: Node) -> void:
	Events.notify.emit(sign_text)
