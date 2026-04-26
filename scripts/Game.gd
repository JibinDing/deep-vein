extends Node2D

const HUD_SCENE := preload("res://scenes/UI/HUD.tscn")
const TILE_MANAGER_SCRIPT := preload("res://scripts/TileManager.gd")
const PATHFINDER_SCRIPT := preload("res://scripts/Pathfinder.gd")
const PLAYER_SCRIPT := preload("res://scripts/Player.gd")
const LANTERN_SCRIPT := preload("res://scripts/LanternSystem.gd")
const BACKPACK_SCRIPT := preload("res://scripts/Backpack.gd")
const MAP_GENERATOR_SCRIPT := preload("res://scripts/MapGenerator.gd")
const FEEDBACK_LAYER_SCRIPT := preload("res://scripts/FeedbackLayer.gd")
const DARKNESS_OVERLAY_SCRIPT := preload("res://scripts/DarknessOverlay.gd")
const MINING_INDICATOR_SCRIPT := preload("res://scripts/MiningIndicator.gd")

var tile_manager
var pathfinder
var player
var lantern
var backpack
var hud
var feedback
var darkness
var mining_indicator
var camera: Camera2D

var map_data: Dictionary
var entrance := Vector2i.ZERO
var session_gold := 0
var session_ores: Dictionary = {}
var current_depth := 0
var elapsed_time := 0.0
var is_evacuating := false
var last_camera_cell := Vector2i(-999, -999)

func _ready() -> void:
	camera = $Camera2D
	_build_world()
	_build_systems()
	_build_feedback()
	_build_mining_indicator()
	_build_darkness()
	_build_hud()

func _process(delta: float) -> void:
	elapsed_time += delta
	if player != null:
		camera.global_position = player.global_position
		_update_visible_map_if_needed()
		current_depth = max(current_depth, player.grid_position.y)
		hud.update_depth(current_depth)
		_update_mining_indicator()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		start_evacuation()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _is_mouse_over_blocking_ui():
			return
		handle_click(get_global_mouse_position())
	elif event is InputEventMouseMotion:
		update_hover(get_global_mouse_position())

func _is_mouse_over_blocking_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null and hovered.mouse_filter == Control.MOUSE_FILTER_STOP

func _build_world() -> void:
	var generator = MAP_GENERATOR_SCRIPT.new()
	map_data = generator.generate()
	entrance = map_data["entrance"]

	tile_manager = TILE_MANAGER_SCRIPT.new()
	add_child(tile_manager)
	tile_manager.set_camera(camera)
	tile_manager.load_map(map_data)

	pathfinder = PATHFINDER_SCRIPT.new()
	add_child(pathfinder)
	pathfinder.setup(tile_manager)

	player = PLAYER_SCRIPT.new()
	add_child(player)
	player.setup(tile_manager, pathfinder, entrance + Vector2i(0, 1))

func _build_systems() -> void:
	var stats: Dictionary = UpgradeDatabase.get_session_stats()
	backpack = BACKPACK_SCRIPT.new()
	backpack.max_weight = float(stats["backpack_max_weight"])
	backpack.changed.connect(_on_backpack_changed)
	backpack.full.connect(_on_backpack_full)

	lantern = LANTERN_SCRIPT.new()
	add_child(lantern)
	lantern.max_lantern = float(stats["lantern_max"])
	lantern.current_lantern = lantern.max_lantern
	lantern.changed.connect(_on_lantern_changed)
	lantern.depleted.connect(start_evacuation)

	player.mine_speed = float(stats["mine_speed"])
	player.mine_power = int(stats["mine_power"])
	player.move_speed = float(stats["move_speed"])
	player.move_step.connect(lantern.on_move_step)
	player.mine_hit.connect(_on_player_mine_hit)
	player.mine_complete.connect(_on_player_mine_complete)

func _build_feedback() -> void:
	feedback = FEEDBACK_LAYER_SCRIPT.new()
	add_child(feedback)

func _build_mining_indicator() -> void:
	mining_indicator = MINING_INDICATOR_SCRIPT.new()
	add_child(mining_indicator)
	mining_indicator.setup(tile_manager)

func _build_darkness() -> void:
	darkness = DARKNESS_OVERLAY_SCRIPT.new()
	add_child(darkness)
	darkness.setup(player, camera)
	darkness.set_lantern(lantern.current_lantern, lantern.max_lantern)

func _build_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.update_lantern(lantern.current_lantern, lantern.max_lantern)
	hud.update_backpack(backpack)
	hud.update_gold(session_gold)

func handle_click(world_pos: Vector2) -> void:
	if is_evacuating:
		return
	var clicked_cell: Vector2i = tile_manager.world_to_cell(world_pos)
	if not tile_manager.is_in_bounds(clicked_cell):
		return
	tile_manager.flash_cell(clicked_cell)
	var cell_type: int = tile_manager.get_cell_type(clicked_cell)
	match cell_type:
		TILE_MANAGER_SCRIPT.CellType.EMPTY:
			player.move_to(clicked_cell)
		TILE_MANAGER_SCRIPT.CellType.ENTRANCE:
			start_evacuation()
		TILE_MANAGER_SCRIPT.CellType.ROCK, TILE_MANAGER_SCRIPT.CellType.ORE, TILE_MANAGER_SCRIPT.CellType.HARD_ROCK:
			var adjacent := get_adjacent_empty_cell(clicked_cell, player.grid_position)
			if adjacent != Vector2i(-1, -1):
				player.move_then_mine(adjacent, clicked_cell)

func update_hover(world_pos: Vector2) -> void:
	if is_evacuating or tile_manager == null:
		tile_manager.set_hover(Vector2i(-1, -1), "none")
		return
	if _is_mouse_over_blocking_ui():
		tile_manager.set_hover(Vector2i(-1, -1), "none")
		return
	var cell: Vector2i = tile_manager.world_to_cell(world_pos)
	if not tile_manager.is_in_bounds(cell):
		tile_manager.set_hover(Vector2i(-1, -1), "none")
		return
	tile_manager.set_hover(cell, _interaction_mode_for_cell(cell))

func _interaction_mode_for_cell(cell: Vector2i) -> String:
	var cell_type: int = tile_manager.get_cell_type(cell)
	match cell_type:
		TILE_MANAGER_SCRIPT.CellType.EMPTY:
			return "move" if not pathfinder.find_path(player.grid_position, cell).is_empty() else "blocked"
		TILE_MANAGER_SCRIPT.CellType.ENTRANCE:
			return "evacuate"
		TILE_MANAGER_SCRIPT.CellType.ROCK, TILE_MANAGER_SCRIPT.CellType.ORE, TILE_MANAGER_SCRIPT.CellType.HARD_ROCK:
			return "mine" if get_adjacent_empty_cell(cell, player.grid_position) != Vector2i(-1, -1) else "blocked"
		_:
			return "blocked"

func get_adjacent_empty_cell(target: Vector2i, player_pos: Vector2i) -> Vector2i:
	var neighbors := [
		target + Vector2i(0, -1),
		target + Vector2i(0, 1),
		target + Vector2i(-1, 0),
		target + Vector2i(1, 0)
	]
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for cell: Vector2i in neighbors:
		if tile_manager.is_walkable(cell):
			var dist := player_pos.distance_squared_to(cell)
			if dist < best_dist:
				best = cell
				best_dist = dist
	return best

func start_evacuation() -> void:
	if is_evacuating:
		return
	is_evacuating = true
	player.is_mining = false
	player.is_moving = false
	player.move_to(entrance + Vector2i(0, 1))
	await _wait_until_player_reaches(entrance + Vector2i(0, 1))
	end_session()

func _wait_until_player_reaches(target: Vector2i) -> void:
	while player.grid_position != target:
		await get_tree().process_frame

func end_session() -> void:
	var session_data := {
		"ores_collected": session_ores,
		"gold_earned": session_gold,
		"depth_reached": current_depth,
		"lantern_remaining": lantern.current_lantern,
		"time_elapsed": elapsed_time
	}
	SaveManager.data["last_session"] = session_data
	SaveManager.add_gold(session_gold)
	SaveManager.record_session(current_depth)
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

func _on_player_mine_hit(cell: Vector2i) -> void:
	lantern.on_mine_action()
	feedback.show_mine_hit(tile_manager.cell_to_world(cell))

func _on_player_mine_complete(cell: Vector2i, ore_id: String) -> void:
	mining_indicator.clear()
	if ore_id != "":
		if backpack.try_add_ore(ore_id):
			var ore = OreDatabase.get_ore(ore_id)
			session_ores[ore_id] = int(session_ores.get(ore_id, 0)) + 1
			session_gold += ore.base_value
			hud.update_gold(session_gold)
			feedback.show_ore_collected(tile_manager.cell_to_world(cell), ore.ore_name, ore.glow_color)
		else:
			feedback.show_plain_mined(tile_manager.cell_to_world(cell))
	else:
		feedback.show_plain_mined(tile_manager.cell_to_world(cell))
	current_depth = max(current_depth, cell.y)

func _update_mining_indicator() -> void:
	if mining_indicator == null:
		return
	if player == null or not player.is_mining:
		mining_indicator.clear()
		return
	var target_cell: Vector2i = player.mine_target
	var current_hp: int = tile_manager.get_cell_hp(target_cell)
	var max_hp: int = 2 if tile_manager.get_cell_type(target_cell) == TILE_MANAGER_SCRIPT.CellType.HARD_ROCK else 1
	var hit_duration: float = 1.0 / max(0.01, player.mine_speed)
	var progress: float = clamp(player.mine_elapsed / hit_duration, 0.0, 1.0)
	mining_indicator.show_for_cell(target_cell, current_hp, max_hp)
	mining_indicator.update_progress(progress, current_hp)

func _on_backpack_changed() -> void:
	hud.update_backpack(backpack)

func _on_backpack_full() -> void:
	hud.show_backpack_full()

func _on_lantern_changed(current: float, max_value: float) -> void:
	hud.update_lantern(current, max_value)
	if darkness != null:
		darkness.set_lantern(current, max_value)

func _update_visible_map_if_needed() -> void:
	var camera_cell: Vector2i = tile_manager.world_to_cell(camera.global_position)
	if camera_cell == last_camera_cell:
		return
	last_camera_cell = camera_cell
	tile_manager.queue_redraw()
