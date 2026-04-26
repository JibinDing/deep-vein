extends Control

const GOLD_ICON_PATH := "res://Art/ui/clean/icon_gold_coin.png"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var data: Dictionary = SaveManager.data.get("last_session", {})
	var lost: bool = bool(data.get("lost", false))

	if lost:
		_build_lost_ui(data)
	else:
		_build_success_ui(data)

func _build_lost_ui(data: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.010, 0.010)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "在矿洞中迷失"
	title.position = Vector2(90, 60)
	title.add_theme_font_size_override("font_size", 52)
	title.modulate = Color(0.78, 0.28, 0.18)
	add_child(title)

	var depth := int(data.get("depth_reached", 0))
	var elapsed := float(data.get("time_elapsed", 0.0))

	var stats := VBoxContainer.new()
	stats.position = Vector2(110, 165)
	stats.add_theme_constant_override("separation", 12)
	add_child(stats)

	for line: String in [
		"到达深度：%dm" % depth,
		"探险时间：%02d:%02d" % [int(elapsed / 60.0), int(elapsed) % 60],
	]:
		var label := Label.new()
		label.text = line
		label.modulate = Color(0.72, 0.62, 0.48)
		label.add_theme_font_size_override("font_size", 22)
		stats.add_child(label)

	var loss_label := Label.new()
	loss_label.text = "本次携带的所有矿石已随你永远留在矿洞深处。"
	loss_label.modulate = Color(0.58, 0.38, 0.28)
	loss_label.add_theme_font_size_override("font_size", 20)
	stats.add_child(loss_label)

	var ores: Dictionary = data.get("ores_collected", {})
	if not ores.is_empty():
		var lost_title := Label.new()
		lost_title.text = "失去的矿石"
		lost_title.position = Vector2(680, 96)
		lost_title.modulate = Color(0.65, 0.28, 0.18)
		lost_title.add_theme_font_size_override("font_size", 28)
		add_child(lost_title)

		var ore_box := GridContainer.new()
		ore_box.columns = 2
		ore_box.position = Vector2(680, 150)
		ore_box.add_theme_constant_override("h_separation", 16)
		ore_box.add_theme_constant_override("v_separation", 12)
		add_child(ore_box)

		for ore_id: String in ores.keys():
			var ore = OreDatabase.get_ore(ore_id)
			var label := Label.new()
			label.custom_minimum_size = Vector2(190, 52)
			label.text = "%s x%d" % [ore.ore_name if ore != null else ore_id, ores[ore_id]]
			label.modulate = Color(0.55, 0.42, 0.32)
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

func _build_success_ui(data: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.032, 0.028)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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
	var elapsed := float(data.get("time_elapsed", 0.0))
	var lantern := float(data.get("lantern_remaining", 0.0))
	for line: String in [
		"深度：%dm" % depth,
		"探险时间：%02d:%02d" % [int(elapsed / 60.0), int(elapsed) % 60],
		"矿灯剩余：%d%%" % int(lantern)
	]:
		var label := Label.new()
		label.text = line
		label.add_theme_font_size_override("font_size", 24)
		stats.add_child(label)

	var warehouse_hint := Label.new()
	warehouse_hint.text = "矿石已存入仓库"
	warehouse_hint.modulate = Color(0.82, 0.70, 0.48)
	warehouse_hint.add_theme_font_size_override("font_size", 20)
	stats.add_child(warehouse_hint)

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
