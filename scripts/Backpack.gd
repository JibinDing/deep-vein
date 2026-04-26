extends RefCounted
class_name Backpack

signal changed
signal full

var max_weight: float = 10.0
var current_weight: float = 0.0
var contents: Dictionary = {}

func try_add_ore(ore_id: String, count: int = 1) -> bool:
	var ore = OreDatabase.get_ore(ore_id)
	if ore == null:
		return false
	var added_weight: float = ore.weight * count
	if current_weight + added_weight > max_weight:
		full.emit()
		return false
	current_weight += added_weight
	contents[ore_id] = int(contents.get(ore_id, 0)) + count
	changed.emit()
	return true

func get_total_value() -> int:
	var total := 0
	for ore_id: String in contents.keys():
		var ore = OreDatabase.get_ore(ore_id)
		if ore != null:
			total += ore.base_value * int(contents[ore_id])
	return total

func get_fill_pct() -> float:
	if max_weight <= 0.0:
		return 0.0
	return current_weight / max_weight
