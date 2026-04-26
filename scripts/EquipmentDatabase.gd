extends Node

var items: Dictionary = {
	"lantern_oil": {
		"name": "矿灯油",
		"description": "精炼灯油，显著延长矿灯燃烧时间。",
		"weight": 1.5,
		"buy_price": 80,
		"effect_key": "lantern_bonus",
		"effect_value": 25.0
	},
	"reinforced_bag": {
		"name": "加固矿袋",
		"description": "坚固的附加矿袋，增加本次携带上限。",
		"weight": 2.0,
		"buy_price": 120,
		"effect_key": "backpack_bonus",
		"effect_value": 4.0
	},
	"speed_boots": {
		"name": "冲劲短靴",
		"description": "轻量化靴底，让你在矿道中移动更快。",
		"weight": 1.0,
		"buy_price": 100,
		"effect_key": "move_speed_bonus",
		"effect_value": 1.5
	},
	"sharp_pick": {
		"name": "锋利镐头",
		"description": "开刃处理的备用镐头，提升挖掘效率。",
		"weight": 1.5,
		"buy_price": 150,
		"effect_key": "mine_speed_bonus",
		"effect_value": 0.4
	},
	"dynamite": {
		"name": "炸药包",
		"description": "爆破4×4区域，站太近会损失矿灯时间。",
		"weight": 1.0,
		"buy_price": 200,
		"effect_key": "dynamite_charges",
		"effect_value": 3
	},
	"probe_hammer": {
		"name": "探矿锤",
		"description": "敲击地面，感知3×3范围内是否藏有矿石。",
		"weight": 0.5,
		"buy_price": 120,
		"effect_key": "probe_charges",
		"effect_value": 5
	}
}

var order := ["lantern_oil", "reinforced_bag", "speed_boots", "sharp_pick", "dynamite", "probe_hammer"]

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func get_all_ids() -> Array:
	return order.duplicate()

func get_owned_count(id: String) -> int:
	return int(SaveManager.data.get("equipment_owned", {}).get(id, 0))

func buy(id: String) -> bool:
	var item := get_item(id)
	if item.is_empty():
		return false
	var price: int = int(item["buy_price"])
	if not SaveManager.spend_gold(price):
		return false
	var owned: Dictionary = SaveManager.data.get("equipment_owned", {})
	owned[id] = int(owned.get(id, 0)) + 1
	SaveManager.data["equipment_owned"] = owned
	SaveManager.save_game()
	return true

func get_loadout_slot_count() -> int:
	return 2 + UpgradeDatabase.get_level("equipment_slots")

func get_loadout() -> Array:
	var slots := get_loadout_slot_count()
	var saved: Array = SaveManager.data.get("loadout", [])
	while saved.size() < slots:
		saved.append("")
	return saved.slice(0, slots)

func save_loadout(loadout: Array) -> void:
	SaveManager.data["loadout"] = loadout
	SaveManager.save_game()

func get_loadout_effects() -> Dictionary:
	var effects := {
		"lantern_bonus": 0.0,
		"backpack_bonus": 0.0,
		"move_speed_bonus": 0.0,
		"mine_speed_bonus": 0.0
	}
	for item_id in get_loadout():
		if item_id == "":
			continue
		var item := get_item(item_id)
		if item.is_empty():
			continue
		var key: String = item["effect_key"]
		effects[key] = float(effects.get(key, 0.0)) + float(item["effect_value"])
	return effects

func get_loadout_weight() -> float:
	var total := 0.0
	for item_id in get_loadout():
		if item_id == "":
			continue
		var item := get_item(item_id)
		if not item.is_empty():
			total += float(item["weight"])
	return total
