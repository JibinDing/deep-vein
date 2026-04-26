extends Node

const ORE_DATA_SCRIPT := preload("res://scripts/OreData.gd")

var ores: Dictionary = {}

func _ready() -> void:
	_register_defaults()

func _register_defaults() -> void:
	ores.clear()
	add_ore("coal", "煤炭", 5, 1.0, 0.60, 0, Color(0.16, 0.16, 0.18))
	add_ore("iron", "铁矿", 15, 1.5, 0.30, 10, Color(0.64, 0.31, 0.18))
	add_ore("crystal", "水晶", 40, 0.8, 0.15, 25, Color(0.18, 0.72, 1.00))
	add_ore("gold", "金矿", 100, 2.0, 0.05, 40, Color(1.00, 0.78, 0.20))

func add_ore(id: String, display_name: String, value: int, ore_weight: float, rarity: float, depth_min: int, color: Color) -> void:
	var ore = ORE_DATA_SCRIPT.new()
	ore.ore_id = id
	ore.ore_name = display_name
	ore.base_value = value
	ore.weight = ore_weight
	ore.rarity = rarity
	ore.depth_min = depth_min
	ore.glow_color = color
	ores[id] = ore

func get_ore(ore_id: String):
	return ores.get(ore_id)

func get_spawnable_ores(depth: int) -> Array:
	var result: Array = []
	for ore in ores.values():
		if depth >= ore.depth_min:
			result.append(ore)
	return result
