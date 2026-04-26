extends Label

var velocity := Vector2(0, -34)
var lifetime := 0.85
var age := 0.0

func setup(display_text: String, text_color: Color) -> void:
	text = display_text
	modulate = text_color
	z_index = 40
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	size = Vector2(140, 32)
	pivot_offset = size * 0.5

func _process(delta: float) -> void:
	age += delta
	position += velocity * delta
	var pct: float = clamp(age / lifetime, 0.0, 1.0)
	modulate.a = 1.0 - pct
	scale = Vector2.ONE * lerp(1.15, 0.92, pct)
	if age >= lifetime:
		queue_free()
