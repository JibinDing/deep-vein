extends Node

const SAVE_PATH := "user://save.json"

var data: Dictionary = {
	"total_gold": 0,
	"upgrades": {},
	"blueprints": [],
	"sessions_played": 0,
	"deepest_depth": 0,
	"total_gold_earned": 0,
	"era": "candle",
	"warehouse": {},
	"equipment_owned": {},
	"loadout": []
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write save file.")
		return
	file.store_string(JSON.stringify(data, "\t"))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		data.merge(parsed, true)

func add_gold(amount: int) -> void:
	data["total_gold"] += amount
	data["total_gold_earned"] += amount
	save_game()

func spend_gold(amount: int) -> bool:
	if data["total_gold"] < amount:
		return false
	data["total_gold"] -= amount
	save_game()
	return true

func get_upgrade_level(upgrade_id: String) -> int:
	return int(data.upgrades.get(upgrade_id, 0))

func set_upgrade_level(upgrade_id: String, level: int) -> void:
	data.upgrades[upgrade_id] = level
	save_game()

func record_session(depth: int) -> void:
	data["sessions_played"] += 1
	data["deepest_depth"] = max(int(data["deepest_depth"]), depth)
	save_game()

func add_to_warehouse(ores: Dictionary) -> void:
	if not data.has("warehouse"):
		data["warehouse"] = {}
	for ore_id: String in ores:
		var count := int(ores[ore_id])
		data["warehouse"][ore_id] = int(data["warehouse"].get(ore_id, 0)) + count
	save_game()

func get_warehouse() -> Dictionary:
	return data.get("warehouse", {})
