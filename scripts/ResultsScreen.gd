extends Control

const GOLD_ICON_PATH := "res://Art/ui/clean/icon_gold_coin.png"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.032, 0.028)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var data: Dictionary = SaveManager.data.get("last_session", {})

	var title := Label.new()
	title.text = "探险结束"
	title.position = Vector2(90, 60)
	title.add_theme_font_size_override("font_size", 46)
	add_child(title)

	var stats := VBoxContainer.new()
	stats.position = Vector2(110, 145)
	stats.add_theme_constant_override("separation", 10)
	add_child(stats)

	var depth := int(data.get("depth_reached", 0))
	var gold := int(data.get("gold_earned", 0))
	var elapsed := float(data.get("time_elapsed", 0.0))
	var lantern := float(data.get("lantern_remaining", 0.0))
	var lines := [
		"深度：%dm" % depth,
		"探险时间：%02d:%02d" % [int(elapsed / 60.0), int(elapsed) % 60],
		"矿灯剩余：%d%%" % int(lantern)
	]
	for line: String in lines:
		var label := Label.new()
		label.text = line
		label.add_theme_font_size_override("font_size", 24)
		stats.add_child(label)

	var gold_row := HBoxContainer.new()
	gold_row.add_theme_constant_override("separation", 8)
	stats.add_child(gold_row)
	gold_row.add_child(_make_icon(GOLD_ICON_PATH, Vector2(30, 30)))
	var gold_result := Label.new()
	gold_result.text = "本次收益：%d" % gold
	gold_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_result.add_theme_font_size_override("font_size", 24)
	gold_row.add_child(gold_result)

	var ores_title := Label.new()
	ores_title.text = "获得资源"
	ores_title.position = Vector2(680, 96)
	ores_title.add_theme_font_size_override("font_size", 28)
	add_child(ores_title)

	var ore_box := GridContainer.new()
	ore_box.columns = 2
	ore_box.position = Vector2(680, 150)
	ore_box.add_theme_constant_override("h_separation", 16)
	ore_box.add_theme_constant_override("v_separation", 12)
	add_child(ore_box)

	var ores: Dictionary = data.get("ores_collected", {})
	if ores.is_empty():
		var empty := Label.new()
		empty.text = "没有带回矿石"
		ore_box.add_child(empty)
	else:
		for ore_id: String in ores.keys():
			var ore = OreDatabase.get_ore(ore_id)
			var label := Label.new()
			label.custom_minimum_size = Vector2(190, 52)
			label.text = "%s x%d" % [ore.ore_name if ore != null else ore_id, ores[ore_id]]
			ore_box.add_child(label)

	var camp_button := Button.new()
	camp_button.text = "返回营地"
	camp_button.position = Vector2(110, 590)
	camp_button.custom_minimum_size = Vector2(180, 52)
	camp_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Camp.tscn"))
	add_child(camp_button)

	var again_button := Button.new()
	again_button.text = "再次下矿"
	again_button.position = Vector2(980, 590)
	again_button.custom_minimum_size = Vector2(180, 52)
	again_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))
	add_child(again_button)

func _make_icon(path: String, size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = size
	icon.size = size
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_png_texture(path)
	return icon

func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
