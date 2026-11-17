extends Node
## 全局信号总线：跨场景/跨系统的通信一律走这里，避免节点互相硬引用。
## 约定：只声明信号，不写业务逻辑。

## --- 玩家 ---
signal player_hp_changed(current: int, max_value: int)
signal player_damaged(amount: int)
signal player_healed(amount: int)
signal player_died
signal player_state_changed(new_state: StringName)
signal prompt_changed(text: String)   # 交互提示（""=隐藏）

## --- 物品 / 背篓 ---
signal item_picked(item_id: String, count: int)
signal item_used(item_id: String)
signal backpack_toggled(opened: bool)

## --- 任务 / 剧情 ---
signal quest_updated(quest_id: String, stage: int)
signal story_flag_changed(flag: String, value: Variant)

## --- 对话 ---
signal dialogue_started(resource_path: String)
signal dialogue_ended(resource_path: String)

## --- 场景 ---
signal scene_change_started(scene_path: String)
signal scene_change_finished(scene_path: String)

## --- 通用 ---
signal notify(text: String)              # 屏幕小提示（拾取/提示条）
signal time_of_day_changed(is_night: bool)
