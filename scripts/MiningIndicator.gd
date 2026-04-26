extends Node2D
class_name MiningIndicator

const TILE_MANAGER_SCRIPT := preload("res://scripts/TileManager.gd")

var tile_manager
var target_cell := Vector2i(-1, -1)
var progress := 0.0
var hp := 1
var max_hp := 1

func setup(manager) -> void:
	tile_manager = manager
	z_index = 50
	z_as_relative = false
	hide()

func show_for_cell(cell: Vector2i, current_hp: int, total_hp: int) -> void:
	target_cell = cell
	hp = max(1, current_hp)
	max_hp = max(1, total_hp)
	show()
	queue_redraw()

func update_progress(value: float, current_hp: int) -> void:
	progress = clamp(value, 0.0, 1.0)
	hp = max(1, current_hp)
	queue_redraw()

func clear() -> void:
	target_cell = Vector2i(-1, -1)
	progress = 0.0
	hide()

func _draw() -> void:
	if tile_manager == null or target_cell == Vector2i(-1, -1):
		return

	var world_pos: Vector2 = tile_manager.cell_to_world(target_cell)
	var size := Vector2(TILE_MANAGER_SCRIPT.CELL_SIZE * 0.82, 6.0)
	var origin := world_pos + Vector2(-size.x * 0.5, -TILE_MANAGER_SCRIPT.CELL_SIZE * 0.64)
	var bg_rect := Rect2(origin, size)
	var fill_rect := Rect2(origin, Vector2(size.x * progress, size.y))

	draw_rect(bg_rect.grow(2.0), Color(0.02, 0.018, 0.014, 0.82), true)
	draw_rect(bg_rect, Color(0.10, 0.08, 0.05, 0.95), true)
	draw_rect(fill_rect, Color(1.0, 0.66, 0.18, 0.95), true)
	draw_rect(bg_rect, Color(0.95, 0.72, 0.28, 0.65), false, 1.0)

	if max_hp > 1:
		_draw_hp_pips(world_pos)

func _draw_hp_pips(world_pos: Vector2) -> void:
	var spacing := 6.0
	var start_x := -float(max_hp - 1) * spacing * 0.5
	var y := -TILE_MANAGER_SCRIPT.CELL_SIZE * 0.36
	for i in range(max_hp):
		var filled := i < hp
		var color := Color(1.0, 0.62, 0.18, 0.9) if filled else Color(0.18, 0.14, 0.10, 0.9)
		draw_circle(world_pos + Vector2(start_x + spacing * i, y), 2.2, color)
