extends Node2D
class_name Player

signal move_step
signal mine_hit(cell: Vector2i)
signal mine_complete(cell: Vector2i, ore_id: String)

var grid_position := Vector2i.ZERO
var is_moving := false
var is_mining := false
var mine_target := Vector2i(-1, -1)
var move_speed := 4.0
var mine_speed := 1.0
var mine_power := 1

const TILE_MANAGER_SCRIPT := preload("res://scripts/TileManager.gd")

var tile_manager
var pathfinder
var path: Array[Vector2i] = []
var pending_mine_target := Vector2i(-1, -1)
var mine_elapsed := 0.0

func setup(manager, finder, start_cell: Vector2i) -> void:
	tile_manager = manager
	pathfinder = finder
	grid_position = start_cell
	position = tile_manager.cell_to_world(grid_position)
	queue_redraw()

func move_to(target: Vector2i) -> void:
	if is_mining:
		return
	var next_path: Array[Vector2i] = pathfinder.find_path(grid_position, target)
	if next_path.is_empty():
		return
	path = next_path
	pending_mine_target = Vector2i(-1, -1)
	is_moving = true

func move_then_mine(move_target: Vector2i, target: Vector2i) -> void:
	if is_mining:
		return
	var next_path: Array[Vector2i] = pathfinder.find_path(grid_position, move_target)
	if next_path.is_empty():
		return
	path = next_path
	pending_mine_target = target
	is_moving = true

func start_mining(target: Vector2i) -> void:
	is_mining = true
	mine_target = target
	mine_elapsed = 0.0

func _process(delta: float) -> void:
	if is_moving:
		_follow_path(delta)
	elif is_mining:
		_process_mining(delta)

func _follow_path(delta: float) -> void:
	if path.is_empty():
		is_moving = false
		if pending_mine_target != Vector2i(-1, -1):
			start_mining(pending_mine_target)
		return

	if path[0] == grid_position:
		path.pop_front()
		return

	var target_pos: Vector2 = tile_manager.cell_to_world(path[0])
	position = position.move_toward(target_pos, move_speed * TILE_MANAGER_SCRIPT.CELL_SIZE * delta)
	if position.distance_to(target_pos) < 0.5:
		grid_position = path.pop_front()
		position = target_pos
		move_step.emit()

func _process_mining(delta: float) -> void:
	mine_elapsed += delta
	if mine_elapsed < 1.0 / mine_speed:
		return
	mine_elapsed = 0.0
	var hp: int = tile_manager.get_cell_hp(mine_target) - mine_power
	mine_hit.emit(mine_target)
	if hp <= 0:
		var ore_id: String = tile_manager.get_cell_ore(mine_target)
		tile_manager.set_cell_type(mine_target, TILE_MANAGER_SCRIPT.CellType.EMPTY)
		pathfinder.set_cell_walkable(mine_target, true)
		is_mining = false
		mine_complete.emit(mine_target, ore_id)
	else:
		tile_manager.set_cell_hp(mine_target, hp)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 11.0, Color(0.95, 0.72, 0.28))
	draw_circle(Vector2.ZERO + Vector2(0, -3), 6.0, Color(0.35, 0.26, 0.18))
