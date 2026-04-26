extends Node
class_name Pathfinder

var astar := AStarGrid2D.new()
var tile_manager

func setup(manager) -> void:
	tile_manager = manager
	astar.region = Rect2i(Vector2i.ZERO, tile_manager.map_size)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	refresh_solids()

func refresh_solids() -> void:
	for y in range(tile_manager.map_size.y):
		for x in range(tile_manager.map_size.x):
			var cell := Vector2i(x, y)
			astar.set_point_solid(cell, not tile_manager.is_walkable(cell))

func set_cell_walkable(cell: Vector2i, walkable: bool) -> void:
	if tile_manager.is_in_bounds(cell):
		astar.set_point_solid(cell, not walkable)

func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not tile_manager.is_in_bounds(from) or not tile_manager.is_in_bounds(to):
		return []
	if astar.is_point_solid(to):
		return []
	return astar.get_id_path(from, to)
