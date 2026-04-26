extends RefCounted
class_name MapGenerator

const TILE_MANAGER_SCRIPT := preload("res://scripts/TileManager.gd")

var width := 40
var height := 200
var rng := RandomNumberGenerator.new()

func generate() -> Dictionary:
	rng.randomize()
	var cells: Dictionary = {}
	var ore_ids: Dictionary = {}
	var hp: Dictionary = {}
	var shaft_x := width / 2

	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			var type := TILE_MANAGER_SCRIPT.CellType.ROCK
			if y == 0:
				type = TILE_MANAGER_SCRIPT.CellType.EMPTY  # 地表上方空气层
			elif y == 1:
				type = TILE_MANAGER_SCRIPT.CellType.ROCK   # 可挖土块层
			else:
				var ore_id := _roll_ore(y - 1)
				if ore_id != "":
					type = TILE_MANAGER_SCRIPT.CellType.ORE
					ore_ids[cell] = ore_id
				elif y > 21 and rng.randf() < 0.08:
					type = TILE_MANAGER_SCRIPT.CellType.HARD_ROCK
				elif y > 51 and rng.randf() < 0.03:
					type = TILE_MANAGER_SCRIPT.CellType.BLOCKED
			cells[cell] = type
			hp[cell] = 2 if type == TILE_MANAGER_SCRIPT.CellType.HARD_ROCK else 1

	return {
		"size": Vector2i(width, height),
		"cells": cells,
		"ore_ids": ore_ids,
		"hp": hp,
		"entrance": Vector2i(shaft_x, 0)
	}

func _roll_ore(depth: int) -> String:
	for ore in OreDatabase.get_spawnable_ores(depth):
		if rng.randf() < ore.rarity * 0.08:
			return ore.ore_id
	return ""
