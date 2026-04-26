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
const FLOOR_TEXTURE_PATH := "res://Art/tiles/processed/floor_empty_64.png"
const ROCK_TEXTURE_PATH := "res://Art/tiles/processed/rock_normal_01_64.png"

var map_size := Vector2i.ZERO
var cells: Dictionary = {}
var ore_ids: Dictionary = {}
var hp: Dictionary = {}
var hover_cell := Vector2i(-1, -1)
var hover_mode := "none"
var clicked_cell := Vector2i(-1, -1)
var click_flash_time := 0.0
var camera: Camera2D
var floor_texture: Texture2D
var rock_texture: Texture2D

func _ready() -> void:
	floor_texture = _load_png_texture(FLOOR_TEXTURE_PATH)
	rock_texture = _load_png_texture(ROCK_TEXTURE_PATH)

func set_camera(target_camera: Camera2D) -> void:
	camera = target_camera

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

func set_hover(cell: Vector2i, mode: String) -> void:
	if hover_cell == cell and hover_mode == mode:
		return
	hover_cell = cell
	hover_mode = mode
	queue_redraw()

func flash_cell(cell: Vector2i) -> void:
	clicked_cell = cell
	click_flash_time = 0.18
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if click_flash_time <= 0.0:
		set_process(false)
		return
	click_flash_time = max(0.0, click_flash_time - delta)
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
	var bounds := _visible_cell_bounds()
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2.ONE * CELL_SIZE)
			_draw_cell(cell, rect)

	if clicked_cell != Vector2i(-1, -1) and click_flash_time > 0.0:
		_draw_cell_highlight(clicked_cell, Color(1.0, 0.78, 0.25, 0.38), 3.0)

	if hover_cell != Vector2i(-1, -1) and is_in_bounds(hover_cell):
		_draw_cell_highlight(hover_cell, _hover_color(), 2.0)

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

func _draw_cell(cell: Vector2i, rect: Rect2) -> void:
	var type := get_cell_type(cell)
	match type:
		CellType.EMPTY:
			_draw_floor(cell, rect)
		CellType.ENTRANCE:
			_draw_entrance(cell, rect)
		CellType.ORE:
			_draw_rock(cell, rect, _ore_base_color(cell))
			_draw_ore_core(cell, rect)
		CellType.HARD_ROCK:
			_draw_rock(cell, rect, Color(0.22, 0.17, 0.13))
			_draw_cracks(cell, rect, Color(0.07, 0.055, 0.045, 0.9), 3)
		CellType.BLOCKED:
			_draw_rock(cell, rect, Color(0.055, 0.055, 0.062))
		_:
			_draw_rock(cell, rect, Color(0.26, 0.25, 0.22))

	if type == CellType.BLOCKED:
		draw_rect(rect, Color(0.012, 0.010, 0.009, 0.12), false, 1.0)

func _draw_floor(cell: Vector2i, rect: Rect2) -> void:
	if floor_texture != null:
		draw_rect(rect.grow(0.75), Color(0.13, 0.12, 0.10), true)
		draw_texture_rect(floor_texture, rect.grow(0.75), false)
		return
	var shade := _cell_noise(cell, 1)
	var base := Color(0.135, 0.12, 0.095).lightened(shade * 0.08)
	draw_rect(rect.grow(-1.0), base, true)
	draw_rect(rect.grow(-4.0), Color(0.19, 0.17, 0.13, 0.22), false, 1.0)
	_draw_specks(cell, rect, Color(0.33, 0.30, 0.24, 0.28), 3)

func _draw_entrance(cell: Vector2i, rect: Rect2) -> void:
	var shade := _cell_noise(cell, 2)
	var base := Color(0.30, 0.20, 0.10).lightened(shade * 0.08)
	draw_rect(rect.grow(-1.0), base, true)
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.55), Vector2(rect.size.x, rect.size.y * 0.45)), Color(0.12, 0.08, 0.045, 0.35), true)
	draw_line(rect.position + Vector2(3, 8), rect.position + Vector2(rect.size.x - 3, 6 + shade * 5.0), Color(0.50, 0.34, 0.15, 0.45), 1.0)

func _draw_rock(cell: Vector2i, rect: Rect2, base_color: Color) -> void:
	if rock_texture != null and get_cell_type(cell) in [CellType.ROCK, CellType.ORE]:
		var tint := base_color.lightened(0.12)
		draw_rect(rect.grow(0.75), base_color.darkened(0.12), true)
		draw_texture_rect(rock_texture, rect.grow(0.75), false, Color(tint.r, tint.g, tint.b, 1.0))
		return
	var shade := _cell_noise(cell, 3)
	var color := base_color.lightened(shade * 0.12).darkened((1.0 - shade) * 0.06)
	draw_rect(rect.grow(-1.0), color, true)
	draw_rect(rect.grow(-3.0), Color(1.0, 0.86, 0.58, 0.035 + shade * 0.025), false, 1.0)
	_draw_cracks(cell, rect, Color(0.03, 0.026, 0.022, 0.45), 2)
	_draw_specks(cell, rect, Color(0.62, 0.58, 0.48, 0.20), 4)

func _draw_ore_core(cell: Vector2i, rect: Rect2) -> void:
	var ore = OreDatabase.get_ore(get_cell_ore(cell))
	if ore == null:
		return
	var center := rect.get_center()
	var color: Color = ore.glow_color
	var pulse := 0.5 + _cell_noise(cell, 8) * 0.5
	draw_circle(center, 9.0 + pulse * 2.0, Color(color.r, color.g, color.b, 0.16))
	draw_circle(center, 5.2, color.darkened(0.1))
	draw_circle(center + Vector2(-1.5, -2.0), 2.2, color.lightened(0.45))
	draw_line(center + Vector2(-5, 5), center + Vector2(4, -6), color.lightened(0.18), 1.5)

func _draw_cracks(cell: Vector2i, rect: Rect2, color: Color, count: int) -> void:
	for i in range(count):
		var a := _cell_noise(cell, 10 + i * 4)
		var b := _cell_noise(cell, 11 + i * 4)
		var c := _cell_noise(cell, 12 + i * 4)
		var start := rect.position + Vector2(5.0 + a * 22.0, 5.0 + b * 22.0)
		var end := start + Vector2(c * 12.0 - 6.0, _cell_noise(cell, 13 + i * 4) * 12.0 - 6.0)
		draw_line(start, end, color, 1.0)

func _draw_specks(cell: Vector2i, rect: Rect2, color: Color, count: int) -> void:
	for i in range(count):
		var x := 4.0 + _cell_noise(cell, 30 + i * 3) * 24.0
		var y := 4.0 + _cell_noise(cell, 31 + i * 3) * 24.0
		var radius := 0.7 + _cell_noise(cell, 32 + i * 3) * 1.1
		draw_circle(rect.position + Vector2(x, y), radius, color)

func _ore_base_color(cell: Vector2i) -> Color:
	var ore = OreDatabase.get_ore(get_cell_ore(cell))
	if ore == null:
		return Color(0.30, 0.25, 0.16)
	return Color(0.24, 0.22, 0.18).lerp(ore.glow_color.darkened(0.55), 0.28)

func _cell_noise(cell: Vector2i, salt: int) -> float:
	var n := int(cell.x * 928371 + cell.y * 364479 + salt * 1013)
	n = (n << 13) ^ n
	var value := (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff
	return float(value) / 2147483647.0

func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _visible_cell_bounds() -> Rect2i:
	if camera == null:
		return Rect2i(Vector2i.ZERO, map_size)
	var viewport_size: Vector2 = get_viewport_rect().size / camera.zoom
	var top_left: Vector2 = camera.get_screen_center_position() - viewport_size * 0.5
	var bottom_right: Vector2 = top_left + viewport_size
	var start := world_to_cell(top_left) - Vector2i(3, 3)
	var end := world_to_cell(bottom_right) + Vector2i(4, 4)
	start.x = clamp(start.x, 0, map_size.x)
	start.y = clamp(start.y, 0, map_size.y)
	end.x = clamp(end.x, 0, map_size.x)
	end.y = clamp(end.y, 0, map_size.y)
	return Rect2i(start, end - start)

func _draw_cell_highlight(cell: Vector2i, color: Color, width: float) -> void:
	var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2.ONE * CELL_SIZE).grow(-2.0)
	draw_rect(rect, Color(color.r, color.g, color.b, color.a * 0.28), true)
	draw_rect(rect, color, false, width)

func _hover_color() -> Color:
	match hover_mode:
		"move":
			return Color(0.55, 0.78, 1.0, 0.55)
		"mine":
			return Color(1.0, 0.72, 0.22, 0.62)
		"evacuate":
			return Color(0.45, 1.0, 0.55, 0.62)
		"blocked":
			return Color(1.0, 0.18, 0.12, 0.48)
		_:
			return Color(1.0, 1.0, 1.0, 0.25)
