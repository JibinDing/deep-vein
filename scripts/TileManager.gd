extends Node2D
class_name TileManager

enum CellType {
	ROCK,
	EMPTY,
	ORE,
	HARD_ROCK,
	BLOCKED,
	ENTRANCE,
	SPECIAL
}

const CELL_SIZE := 32

var map_size := Vector2i.ZERO
var cells: Dictionary = {}
var ore_ids: Dictionary = {}
var hp: Dictionary = {}

func load_map(map_data: Dictionary) -> void:
	map_size = map_data["size"]
	cells = map_data["cells"]
	ore_ids = map_data["ore_ids"]
	hp = map_data["hp"]
	queue_redraw()

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y

func is_walkable(cell: Vector2i) -> bool:
	var type := get_cell_type(cell)
	return type == CellType.EMPTY or type == CellType.ENTRANCE

func get_cell_type(cell: Vector2i) -> int:
	return cells.get(cell, CellType.BLOCKED)

func set_cell_type(cell: Vector2i, type: int) -> void:
	cells[cell] = type
	if type != CellType.ORE:
		ore_ids.erase(cell)
	queue_redraw()

func get_cell_hp(cell: Vector2i) -> int:
	return int(hp.get(cell, 1))

func set_cell_hp(cell: Vector2i, value: int) -> void:
	hp[cell] = value

func get_cell_ore(cell: Vector2i) -> String:
	return String(ore_ids.get(cell, ""))

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / CELL_SIZE), floori(world_pos.y / CELL_SIZE))

func _draw() -> void:
	for y in range(map_size.y):
		for x in range(map_size.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2.ONE * CELL_SIZE)
			draw_rect(rect.grow(-1.0), _color_for_cell(cell), true)
			draw_rect(rect, Color(0.05, 0.045, 0.04, 0.8), false, 1.0)

func _color_for_cell(cell: Vector2i) -> Color:
	match get_cell_type(cell):
		CellType.EMPTY:
			return Color(0.16, 0.14, 0.11)
		CellType.ENTRANCE:
			return Color(0.34, 0.24, 0.12)
		CellType.ORE:
			var ore = OreDatabase.get_ore(get_cell_ore(cell))
			return ore.glow_color.darkened(0.25) if ore != null else Color(0.75, 0.58, 0.12)
		CellType.HARD_ROCK:
			return Color(0.22, 0.16, 0.12)
		CellType.BLOCKED:
			return Color(0.07, 0.07, 0.08)
		_:
			return Color(0.25, 0.24, 0.22)
