class_name ItemDB
## 物品定义表：背篓显示与使用效果的数据源。

const DB := {
	"candy": {
		"name": "橘子糖",
		"desc": "陈婆小卖部的糖。甜的，让人想起补给船还在的日子。",
		"icon": "res://assets/ui/icons_kyrises/candy_01a.png",
		"heal": 8,
	},
	"biscuit": {
		"name": "压缩饼干",
		"desc": "研究所换来的那批货。硬，但顶饿。",
		"icon": "res://assets/sprites/custom/biscuit.png",
		"heal": 12,
	},
	"stone": {
		"name": "石子",
		"desc": "弹弓用的石子。沙滩上到处都是。",
		"icon": "res://assets/sprites/custom/stone.png",
		"heal": 0,
	},
	"match": {
		"name": "火柴",
		"desc": "陈婆塞的。山上冷，也黑。",
		"icon": "res://assets/sprites/custom/matchbox.png",
		"heal": 0,
	},
	"map": {
		"name": "岛内公路图",
		"desc": "从服务区墙上裁下来的。红颜色一条路，从镇子一路往北。",
		"icon": "res://assets/sprites/custom/map_item.png",
		"heal": 0,
	},
}


static func get_item(id: String) -> Dictionary:
	return DB.get(id, {"name": id, "desc": "", "icon": "", "heal": 0})


static func display_name(id: String) -> String:
	return get_item(id)["name"]
