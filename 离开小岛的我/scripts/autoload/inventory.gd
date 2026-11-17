extends Node
## 背篓（背包）：item_id -> 数量。对话/拾取/存档都经这里。

var items: Dictionary = {}


func add_item(id: String, count := 1) -> void:
	items[id] = items.get(id, 0) + count
	Events.item_picked.emit(id, count)


func remove_item(id: String, count := 1) -> bool:
	var have: int = items.get(id, 0)
	if have < count:
		return false
	have -= count
	if have == 0:
		items.erase(id)
	else:
		items[id] = have
	return true


func count(id: String) -> int:
	return items.get(id, 0)


func all() -> Dictionary:
	return items.duplicate()


func clear() -> void:
	items.clear()
