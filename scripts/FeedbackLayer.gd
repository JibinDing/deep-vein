extends Node2D
class_name FeedbackLayer

const FLOATING_TEXT_SCRIPT := preload("res://scripts/FloatingText.gd")
const PARTICLE_SCRIPT := preload("res://scripts/MineParticle.gd")

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func show_mine_hit(world_pos: Vector2) -> void:
	spawn_burst(world_pos, Color(0.42, 0.39, 0.34), 7, 54.0)

func show_ore_collected(world_pos: Vector2, ore_name: String, ore_color: Color) -> void:
	spawn_burst(world_pos, ore_color, 14, 86.0)
	spawn_floating_text(world_pos + Vector2(0, -22), "%s +1" % ore_name, ore_color.lightened(0.25))

func show_plain_mined(world_pos: Vector2) -> void:
	spawn_burst(world_pos, Color(0.52, 0.48, 0.40), 5, 42.0)

func spawn_floating_text(world_pos: Vector2, display_text: String, text_color: Color) -> void:
	var floating_text = FLOATING_TEXT_SCRIPT.new()
	add_child(floating_text)
	floating_text.global_position = world_pos - Vector2(70, 16)
	floating_text.setup(display_text, text_color)

func spawn_burst(world_pos: Vector2, particle_color: Color, count: int, speed: float) -> void:
	for i in range(count):
		var particle = PARTICLE_SCRIPT.new()
		add_child(particle)
		particle.global_position = world_pos + Vector2(rng.randf_range(-5.0, 5.0), rng.randf_range(-5.0, 5.0))
		var angle := rng.randf_range(0.0, TAU)
		var velocity := Vector2.RIGHT.rotated(angle) * rng.randf_range(speed * 0.35, speed)
		var radius := rng.randf_range(1.8, 3.4)
		var lifetime := rng.randf_range(0.28, 0.56)
		particle.setup(velocity, particle_color, radius, lifetime)
