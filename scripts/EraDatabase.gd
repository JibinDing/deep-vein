extends Node

const ERAS := ["candle", "gas_lamp", "electric"]

var era_data := {
	"candle": {
		"name": "蜡烛时代",
		"description": "最原始的照明方式。火焰微弱，随时可能熄灭。",
		"time_rate": 1.2,
		"mine_cost": 2.0,
		"move_cost": 0.12,
		"light_radius_base": 90.0,
		"unlock_gold": 0,
		"unlock_ores": {}
	},
	"gas_lamp": {
		"name": "矿灯时代",
		"description": "燃油矿灯，稳定持久，是矿工的标配装备。",
		"time_rate": 0.8,
		"mine_cost": 1.5,
		"move_cost": 0.08,
		"light_radius_base": 140.0,
		"unlock_gold": 800,
		"unlock_ores": {"iron": 10}
	},
	"electric": {
		"name": "电灯时代",
		"description": "电力照明，亮如白昼，大幅延长深层作业时间。",
		"time_rate": 0.45,
		"mine_cost": 1.0,
		"move_cost": 0.05,
		"light_radius_base": 200.0,
		"unlock_gold": 3000,
		"unlock_ores": {"crystal": 15}
	}
}

func get_current_era() -> String:
	return String(SaveManager.data.get("era", "candle"))

func get_era(era_id: String) -> Dictionary:
	return era_data.get(era_id, era_data["candle"])

func get_current_era_data() -> Dictionary:
	return get_era(get_current_era())

func get_next_era() -> String:
	var current := get_current_era()
	var idx := ERAS.find(current)
	if idx < 0 or idx >= ERAS.size() - 1:
		return ""
	return ERAS[idx + 1]

func is_max_era() -> bool:
	return get_next_era() == ""

func can_unlock_next() -> String:
	var next := get_next_era()
	if next == "":
		return "already_max"
	var data := get_era(next)
	var gold_cost := int(data["unlock_gold"])
	if int(SaveManager.data.get("total_gold", 0)) < gold_cost:
		return "need_gold"
	var ore_req: Dictionary = data["unlock_ores"]
	var warehouse: Dictionary = SaveManager.data.get("warehouse", {})
	for ore_id in ore_req:
		if int(warehouse.get(ore_id, 0)) < int(ore_req[ore_id]):
			return "need_ore"
	return "ok"

func unlock_next() -> bool:
	if can_unlock_next() != "ok":
		return false
	var next := get_next_era()
	var data := get_era(next)
	var gold_cost := int(data["unlock_gold"])
	SaveManager.spend_gold(gold_cost)
	var ore_req: Dictionary = data["unlock_ores"]
	for ore_id in ore_req:
		var needed := int(ore_req[ore_id])
		var have := int(SaveManager.data["warehouse"].get(ore_id, 0))
		SaveManager.data["warehouse"][ore_id] = have - needed
		if int(SaveManager.data["warehouse"][ore_id]) <= 0:
			SaveManager.data["warehouse"].erase(ore_id)
	SaveManager.data["era"] = next
	SaveManager.save_game()
	return true
