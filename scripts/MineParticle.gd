extends Node2D

var velocity := Vector2.ZERO
var radius := 2.5
var lifetime := 0.45
var age := 0.0
var color := Color.WHITE

func setup(start_velocity: Vector2, particle_color: Color, particle_radius: float, particle_lifetime: float) -> void:
	velocity = start_velocity
	color = particle_color
	radius = particle_radius
	lifetime = particle_lifetime
	z_index = 30

func _process(delta: float) -> void:
	age += delta
	position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, 220.0 * delta)
	queue_redraw()
	if age >= lifetime:
		queue_free()

func _draw() -> void:
	var pct: float = clamp(age / lifetime, 0.0, 1.0)
	var draw_color := color
	draw_color.a = 1.0 - pct
	draw_circle(Vector2.ZERO, radius * lerp(1.0, 0.35, pct), draw_color)
