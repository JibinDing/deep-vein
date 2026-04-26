extends Node2D
class_name DarknessOverlay

var player
var camera: Camera2D
var lantern_pct := 1.0
var time := 0.0

var min_radius := 72.0
var max_radius := 210.0
var feather := 76.0

func setup(target_player, target_camera: Camera2D) -> void:
	player = target_player
	camera = target_camera
	z_index = 80
	z_as_relative = false
	set_process(true)

func set_lantern(current: float, max_value: float) -> void:
	if max_value <= 0.0:
		lantern_pct = 0.0
	else:
		lantern_pct = clamp(current / max_value, 0.0, 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	if player == null or camera == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size / camera.zoom
	var center: Vector2 = camera.get_screen_center_position()
	var player_pos: Vector2 = player.global_position
	var radius: float = _current_radius()
	var feather_radius: float = radius + feather
	var cover_radius: float = player_pos.distance_to(center) + viewport_size.length() * 0.75 + feather_radius

	_draw_feather_ring(player_pos, radius, feather_radius)
	_draw_outer_darkness(player_pos, feather_radius, cover_radius)

func _draw_outer_darkness(center: Vector2, inner_radius: float, outer_radius: float) -> void:
	_draw_ring(center, inner_radius, outer_radius, _darkness_alpha(), _darkness_alpha())

func _draw_feather_ring(center: Vector2, inner_radius: float, outer_radius: float) -> void:
	_draw_ring(center, inner_radius, outer_radius, 0.0, _darkness_alpha())

func _draw_ring(center: Vector2, inner_radius: float, outer_radius: float, inner_alpha: float, outer_alpha: float) -> void:
	var segments: int = 72
	for i in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var inner0: Vector2 = center + Vector2.RIGHT.rotated(a0) * inner_radius
		var inner1: Vector2 = center + Vector2.RIGHT.rotated(a1) * inner_radius
		var outer1: Vector2 = center + Vector2.RIGHT.rotated(a1) * outer_radius
		var outer0: Vector2 = center + Vector2.RIGHT.rotated(a0) * outer_radius
		draw_polygon(
			PackedVector2Array([inner0, inner1, outer1, outer0]),
			PackedColorArray([
				Color(0.01, 0.008, 0.006, inner_alpha),
				Color(0.01, 0.008, 0.006, inner_alpha),
				Color(0.01, 0.008, 0.006, outer_alpha),
				Color(0.01, 0.008, 0.006, outer_alpha)
			])
		)

func _current_radius() -> float:
	var pct: float = lantern_pct
	var radius: float = lerp(min_radius, max_radius, pct)
	if pct < 0.2:
		var flicker: float = sin(time * 22.0) * 0.08 + sin(time * 47.0) * 0.045
		radius *= clamp(1.0 + flicker, 0.82, 1.08)
	return radius

func _darkness_alpha() -> float:
	var alpha: float = lerp(0.98, 0.92, lantern_pct)
	if lantern_pct < 0.2:
		alpha += (sin(time * 31.0) + 1.0) * 0.015
	return clamp(alpha, 0.90, 0.99)
