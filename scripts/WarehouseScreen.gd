extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg_texture := TextureRect.new()
	bg_texture.texture = _load_png_texture("res://Art/ui/warehouse.png")
	bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_texture)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.018, 0.014, 0.45)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "仓库"
	title.position = Vector2(72, 44)
	title.add_theme_font_size_override("font_size", 46)
	add_child(title)

	# ── 矿石区 ──
	var ore_section_title := Label.new()
	ore_section_title.text = "矿石"
	ore_section_title.position = Vector2(72, 114)
	ore_section_title.modulate = Color(0.88, 0.76, 0.50)
	ore_section_title.add_theme_font_size_override("font_size", 22)
	add_child(ore_section_title)

	var warehouse := SaveManager.get_warehouse()
	if warehouse.is_empty():
		var empty := Label.new()
		empty.text = "还没有矿石，下矿带些回来吧。"
		empty.position = Vector2(72, 150)
		empty.modulate = Color(0.60, 0.52, 0.38)
		empty.add_theme_font_size_override("font_size", 18)
		add_child(empty)
	else:
		var ore_grid := GridContainer.new()
		ore_grid.columns = 4
		ore_grid.position = Vector2(72, 148)
		ore_grid.add_theme_constant_override("h_separation", 16)
		ore_grid.add_theme_constant_override("v_separation", 12)
		add_child(ore_grid)
		for ore_id: String in warehouse.keys():
			ore_grid.add_child(_make_ore_card(ore_id, int(warehouse[ore_id])))

	# ── 装备区 ──
	var equip_section_title := Label.new()
	equip_section_title.text = "装备"
	equip_section_title.position = Vector2(72, 380)
	equip_section_title.modulate = Color(0.88, 0.76, 0.50)
	equip_section_title.add_theme_font_size_override("font_size", 22)
	add_child(equip_section_title)

	var owned: Dictionary = SaveManager.data.get("equipment_owned", {})
	var has_equipment := false
	for id in owned:
		if int(owned[id]) > 0:
			has_equipment = true
			break

	if not has_equipment:
		var empty := Label.new()
		empty.text = "还没有装备，去商人处购买吧。"
		empty.position = Vector2(72, 416)
		empty.modulate = Color(0.60, 0.52, 0.38)
		empty.add_theme_font_size_override("font_size", 18)
		add_child(empty)
	else:
		var equip_grid := GridContainer.new()
		equip_grid.columns = 4
		equip_grid.position = Vector2(72, 414)
		equip_grid.add_theme_constant_override("h_separation", 16)
		equip_grid.add_theme_constant_override("v_separation", 12)
		add_child(equip_grid)
		for item_id: String in EquipmentDatabase.get_all_ids():
			var count := int(owned.get(item_id, 0))
			if count > 0:
				equip_grid.add_child(_make_equip_card(item_id, count))

	var back_button := Button.new()
	back_button.text = "返回营地"
	back_button.position = Vector2(72, 630)
	back_button.custom_minimum_size = Vector2(180, 52)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Camp.tscn"))
	add_child(back_button)

func _make_ore_card(ore_id: String, count: int) -> PanelContainer:
	var ore = OreDatabase.get_ore(ore_id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(272, 68)
	panel.add_theme_stylebox_override("panel", _make_card_style())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon_tex := _load_png_texture("res://Art/ui/resource_icon/icon_%s.png" % ore_id)
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	else:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16)
		dot.color = ore.glow_color if ore != null else Color(0.75, 0.58, 0.12)
		row.add_child(dot)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = ore.ore_name if ore != null else ore_id
	name_label.add_theme_font_size_override("font_size", 17)
	info.add_child(name_label)

	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.modulate = Color(0.82, 0.70, 0.48)
	count_label.add_theme_font_size_override("font_size", 14)
	info.add_child(count_label)

	return panel

func _make_equip_card(item_id: String, count: int) -> PanelContainer:
	var item := EquipmentDatabase.get_item(item_id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(272, 68)
	panel.add_theme_stylebox_override("panel", _make_card_style())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(12, 12)
	dot.color = Color(0.68, 0.52, 0.28)
	row.add_child(dot)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = String(item.get("name", item_id))
	name_label.add_theme_font_size_override("font_size", 17)
	info.add_child(name_label)

	var sub := Label.new()
	sub.text = "x%d  %.1f kg/个" % [count, float(item.get("weight", 0))]
	sub.modulate = Color(0.72, 0.62, 0.42)
	sub.add_theme_font_size_override("font_size", 13)
	info.add_child(sub)

	return panel

func _make_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.07, 0.92)
	style.border_color = Color(0.58, 0.42, 0.18, 0.52)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
