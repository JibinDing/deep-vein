extends Node

var upgrades: Dictionary = {
	"backpack_size": {
		"name": "背包扩容",
		"category": "survival",
		"icon": "backpack",
		"costs": [200, 350, 500, 800, 1200],
		"description": "扩大背包容量，让你能带回更多矿石。",
		"next_effect": "背包容量 +2",
		"stat": "backpack_max_weight",
		"per_level": 2.0
	},
	"lantern_duration": {
		"name": "灯具改良",
		"category": "survival",
		"icon": "lantern",
		"costs": [150, 280, 420, 650, 1000],
		"description": "提高矿灯燃烧效率，延长每次下矿时间。",
		"next_effect": "矿灯上限 +20",
		"stat": "lantern_max",
		"per_level": 20.0
	},
	"mine_speed": {
		"name": "镐头强化",
		"category": "mining",
		"icon": "pickaxe",
		"costs": [300, 480, 700, 1000, 1500],
		"description": "优化镐头配重，让每次挥镐更快完成。",
		"next_effect": "挖掘速度 +15%",
		"stat": "mine_speed",
		"per_level": 0.15
	},
	"mine_power": {
		"name": "破岩强化",
		"category": "mining",
		"icon": "pickaxe",
		"costs": [500, 900, 1500],
		"description": "强化镐头冲击力，更适合处理硬岩。",
		"next_effect": "挖掘力量 +1",
		"stat": "mine_power",
		"per_level": 1
	},
	"move_speed": {
		"name": "矿靴改良",
		"category": "mobility",
		"icon": "boots",
		"costs": [220, 360, 540, 780],
		"description": "加固靴底和脚踝支撑，提高矿洞移动速度。",
		"next_effect": "移动速度 +0.25",
		"stat": "move_speed",
		"per_level": 0.25
	}
}

var order := [
	"backpack_size",
	"lantern_duration",
	"mine_speed",
	"mine_power",
	"move_speed"
]

func get_upgrade_ids() -> Array:
	return order.duplicate()

func get_upgrade(id: String) -> Dictionary:
	return upgrades.get(id, {})

func get_level(id: String) -> int:
	return SaveManager.get_upgrade_level(id)

func get_max_level(id: String) -> int:
	var info := get_upgrade(id)
	return info.get("costs", []).size()

func is_maxed(id: String) -> bool:
	return get_level(id) >= get_max_level(id)

func get_next_cost(id: String) -> int:
	var info := get_upgrade(id)
	var costs: Array = info.get("costs", [])
	var level := get_level(id)
	if level >= costs.size():
		return -1
	return int(costs[level])

func can_purchase(id: String) -> bool:
	var cost := get_next_cost(id)
	return cost >= 0 and SaveManager.data["total_gold"] >= cost

func purchase(id: String) -> bool:
	if not can_purchase(id):
		return false
	var cost := get_next_cost(id)
	if not SaveManager.spend_gold(cost):
		return false
	SaveManager.set_upgrade_level(id, get_level(id) + 1)
	return true

func get_effect_text(id: String) -> String:
	var info := get_upgrade(id)
	return String(info.get("next_effect", ""))

func get_stat_bonus(stat: String) -> float:
	var total := 0.0
	for id: String in upgrades.keys():
		var info: Dictionary = upgrades[id]
		if info.get("stat", "") == stat:
			total += float(info.get("per_level", 0.0)) * get_level(id)
	return total

func get_session_stats() -> Dictionary:
	return {
		"backpack_max_weight": 10.0 + get_stat_bonus("backpack_max_weight"),
		"lantern_max": 100.0 + get_stat_bonus("lantern_max"),
		"mine_speed": 1.0 + get_stat_bonus("mine_speed"),
		"mine_power": 1 + int(get_stat_bonus("mine_power")),
		"move_speed": 4.0 + get_stat_bonus("move_speed")
	}
