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
var dynamite_charges := 0
var dynamite_mode := false
var dynamite_planted_cell := Vector2i(-1, -1)
var dynamite_countdown := 0.0
var probe_charges := 0
var probe_mode := false

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
	if dynamite_countdown > 0.0:
		var prev_sec := int(dynamite_countdown)
		dynamite_countdown -= delta
		if dynamite_countdown <= 0.0:
			dynamite_countdown = 0.0
			_explode_dynamite()
		elif int(dynamite_countdown) != prev_sec:
			hud.update_dynamite_countdown(int(dynamite_countdown))
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
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		if dynamite_charges > 0:
			dynamite_mode = not dynamite_mode
			probe_mode = false
			hud.update_dynamite(dynamite_charges, dynamite_mode)
			hud.update_probe(probe_charges, false)
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		if probe_charges > 0:
			probe_mode = not probe_mode
			dynamite_mode = false
			hud.update_probe(probe_charges, probe_mode)
			hud.update_dynamite(dynamite_charges, false)
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
	player.setup(tile_manager, pathfinder, entrance)

func _build_systems() -> void:
	var stats: Dictionary = UpgradeDatabase.get_session_stats()
	var equip: Dictionary = EquipmentDatabase.get_loadout_effects()
	var equip_weight: float = EquipmentDatabase.get_loadout_weight()

	backpack = BACKPACK_SCRIPT.new()
	backpack.max_weight = float(stats["backpack_max_weight"]) + float(equip.get("backpack_bonus", 0.0)) - equip_weight
	backpack.changed.connect(_on_backpack_changed)
	backpack.full.connect(_on_backpack_full)

	lantern = LANTERN_SCRIPT.new()
	add_child(lantern)
	lantern.max_lantern = float(stats["lantern_max"]) + float(equip.get("lantern_bonus", 0.0))
	lantern.current_lantern = lantern.max_lantern
	lantern.changed.connect(_on_lantern_changed)
	lantern.depleted.connect(_on_lantern_depleted)

	player.mine_speed = float(stats["mine_speed"]) + float(equip.get("mine_speed_bonus", 0.0))
	player.mine_power = int(stats["mine_power"])
	player.move_speed = float(stats["move_speed"]) + float(equip.get("move_speed_bonus", 0.0))
	player.move_step.connect(lantern.on_move_step)
	player.mine_hit.connect(_on_player_mine_hit)
	player.mine_complete.connect(_on_player_mine_complete)

	dynamite_charges = int(equip.get("dynamite_charges", 0))
	probe_charges = int(equip.get("probe_charges", 0))

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
	darkness.set_lantern(lantern.current_lantern, lantern.max_lantern, lantern.get_remaining_seconds())

func _build_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.update_lantern(lantern.current_lantern, lantern.max_lantern, lantern.get_remaining_seconds())
	hud.update_backpack(backpack)
	hud.update_dynamite(dynamite_charges, false)
	hud.update_probe(probe_charges, false)

func handle_click(world_pos: Vector2) -> void:
	if is_evacuating:
		return
	var clicked_cell: Vector2i = tile_manager.world_to_cell(world_pos)
	if not tile_manager.is_in_bounds(clicked_cell):
		return

	if dynamite_mode and dynamite_charges > 0:
		if not _is_adjacent_to_player(clicked_cell):
			feedback.spawn_floating_text(tile_manager.cell_to_world(clicked_cell), "需要靠近放置", Color(0.9, 0.4, 0.2))
			return
		_use_dynamite(clicked_cell)
		return
	if probe_mode and probe_charges > 0:
		if not _is_adjacent_to_player(clicked_cell):
			feedback.spawn_floating_text(tile_manager.cell_to_world(clicked_cell), "需要靠近探测", Color(0.5, 0.8, 1.0))
			return
		_use_probe(clicked_cell)
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

func _is_adjacent_to_player(cell: Vector2i) -> bool:
	var diff: Vector2i = cell - player.grid_position
	return (abs(diff.x) == 1 and diff.y == 0) or (diff.x == 0 and abs(diff.y) == 1)

func _use_dynamite(center: Vector2i) -> void:
	dynamite_charges -= 1
	dynamite_mode = false
	dynamite_planted_cell = center
	dynamite_countdown = 5.0
	hud.update_dynamite(dynamite_charges, false)
	hud.update_dynamite_countdown(5)
	feedback.spawn_floating_text(tile_manager.cell_to_world(center), "💣 5s", Color(1.0, 0.55, 0.10))

func _explode_dynamite() -> void:
	var center := dynamite_planted_cell
	dynamite_planted_cell = Vector2i(-1, -1)
	hud.update_dynamite_countdown(-1)

	for dy in range(-1, 3):
		for dx in range(-1, 3):
			var cell := center + Vector2i(dx, dy)
			if not tile_manager.is_in_bounds(cell):
				continue
			var ore_id: String = tile_manager.instant_mine(cell)
			if tile_manager.get_cell_type(cell) == TILE_MANAGER_SCRIPT.CellType.EMPTY:
				pathfinder.set_cell_walkable(cell, true)
			if ore_id != "":
				if backpack.try_add_ore(ore_id):
					session_ores[ore_id] = int(session_ores.get(ore_id, 0)) + 1
				feedback.show_ore_collected(tile_manager.cell_to_world(cell), ore_id, Color.ORANGE)

	var dist: float = Vector2(player.grid_position).distance_to(Vector2(center))
	if dist <= 3.0:
		var penalty: float = 30.0 * (1.0 - dist / 3.0)
		lantern.drain(penalty)
	feedback.show_plain_mined(tile_manager.cell_to_world(center))

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
	player.move_to(entrance)
	await _wait_until_player_reaches(entrance)
	end_session()

func _wait_until_player_reaches(target: Vector2i) -> void:
	while player.grid_position != target:
		await get_tree().process_frame

func end_session() -> void:
	var session_data := {
		"ores_collected": session_ores,
		"depth_reached": current_depth,
		"lantern_remaining": lantern.current_lantern,
		"time_elapsed": elapsed_time,
		"lost": false
	}
	SaveManager.data["last_session"] = session_data
	SaveManager.add_to_warehouse(session_ores)
	SaveManager.record_session(current_depth)
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

func _on_lantern_depleted() -> void:
	if is_evacuating:
		return
	is_evacuating = true
	player.is_mining = false
	player.is_moving = false
	var session_data := {
		"ores_collected": session_ores,
		"depth_reached": current_depth,
		"lantern_remaining": 0.0,
		"time_elapsed": elapsed_time,
		"lost": true
	}
	SaveManager.data["last_session"] = session_data
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

func _use_probe(center: Vector2i) -> void:
	probe_charges -= 1
	probe_mode = false
	hud.update_probe(probe_charges, false)

	var found := false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell := center + Vector2i(dx, dy)
			if tile_manager.is_in_bounds(cell) and tile_manager.get_cell_type(cell) == TILE_MANAGER_SCRIPT.CellType.ORE:
				found = true
				break

	var world_pos: Vector2 = tile_manager.cell_to_world(center)
	if found:
		feedback.spawn_floating_text(world_pos, "⚒ 附近有矿！", Color(1.0, 0.82, 0.22))
	else:
		feedback.spawn_floating_text(world_pos, "附近无矿", Color(0.58, 0.52, 0.42))

func _on_backpack_changed() -> void:
	hud.update_backpack(backpack)

func _on_backpack_full() -> void:
	hud.show_backpack_full()

func _on_lantern_changed(current: float, max_value: float) -> void:
	hud.update_lantern(current, max_value, lantern.get_remaining_seconds())
	if darkness != null:
		darkness.set_lantern(current, max_value, lantern.get_remaining_seconds())

func _update_visible_map_if_needed() -> void:
	var camera_cell: Vector2i = tile_manager.world_to_cell(camera.global_position)
	if camera_cell == last_camera_cell:
		return
	last_camera_cell = camera_cell
	tile_manager.queue_redraw()
