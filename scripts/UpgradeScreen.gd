extends Control

const CAMP_BACKGROUND_PATH := "res://Art/ui/camp.png"
const GOLD_ICON_PATH := "res://Art/ui/clean/icon_gold_coin.png"

var gold_label: Label
var upgrades_grid: GridContainer

func _ready() -> void:
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var bg_texture := TextureRect.new()
	bg_texture.texture = _load_png_texture(CAMP_BACKGROUND_PATH)
	bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_texture)

	var bg_overlay := ColorRect.new()
	bg_overlay.color = Color(0.015, 0.012, 0.010, 0.58)
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)

	var title := Label.new()
	title.text = "升级工坊"
	title.position = Vector2(48, 34)
	title.add_theme_font_size_override("font_size", 38)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "永久强化营地装备，影响下一次下矿。"
	subtitle.position = Vector2(52, 86)
	subtitle.modulate = Color(0.82, 0.72, 0.52)
	add_child(subtitle)

	var gold_row := HBoxContainer.new()
	gold_row.position = Vector2(1000, 38)
	gold_row.add_theme_constant_override("separation", 8)
	add_child(gold_row)
	gold_row.add_child(_make_icon(GOLD_ICON_PATH, Vector2(30, 30)))
	gold_label = Label.new()
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 22)
	gold_row.add_child(gold_label)

	var back_button := Button.new()
	back_button.text = "返回营地"
	back_button.position = Vector2(52, 620)
	back_button.custom_minimum_size = Vector2(160, 52)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Camp.tscn"))
	add_child(back_button)

	upgrades_grid = GridContainer.new()
	upgrades_grid.columns = 3
	upgrades_grid.position = Vector2(70, 145)
	upgrades_grid.add_theme_constant_override("h_separation", 18)
	upgrades_grid.add_theme_constant_override("v_separation", 16)
	add_child(upgrades_grid)

func _refresh() -> void:
	gold_label.text = "%d" % SaveManager.data["total_gold"]
	for child in upgrades_grid.get_children():
		child.queue_free()
	for id: String in UpgradeDatabase.get_upgrade_ids():
		upgrades_grid.add_child(_make_upgrade_card(id))

func _make_upgrade_card(id: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 180)
	card.add_theme_stylebox_override("panel", _make_card_style(id))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var info: Dictionary = UpgradeDatabase.get_upgrade(id)
	var level := UpgradeDatabase.get_level(id)
	var max_level := UpgradeDatabase.get_max_level(id)
	var maxed := UpgradeDatabase.is_maxed(id)
	var cost := UpgradeDatabase.get_next_cost(id)

	var title := Label.new()
	title.text = "%s  %d/%d" % [info["name"], level, max_level]
	title.add_theme_font_size_override("font_size", 19)
	box.add_child(title)

	var category := Label.new()
	category.text = _category_name(String(info.get("category", "")))
	category.modulate = Color(0.80, 0.64, 0.36)
	box.add_child(category)

	var desc := Label.new()
	desc.text = info["description"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(320, 42)
	box.add_child(desc)

	var effect := Label.new()
	effect.text = "下一等级：%s" % UpgradeDatabase.get_effect_text(id) if not maxed else "已达到最高等级"
	effect.modulate = Color(0.93, 0.80, 0.48)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(effect)

	var button := Button.new()
	button.text = "已满级" if maxed else "升级 %d" % cost
	button.disabled = maxed or not UpgradeDatabase.can_purchase(id)
	button.pressed.connect(func():
		if UpgradeDatabase.purchase(id):
			_refresh()
	)
	box.add_child(button)

	return card

func _make_card_style(id: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var affordable := UpgradeDatabase.can_purchase(id)
	var maxed := UpgradeDatabase.is_maxed(id)
	style.bg_color = Color(0.18, 0.135, 0.078, 0.90) if affordable else Color(0.085, 0.070, 0.055, 0.88)
	if maxed:
		style.bg_color = Color(0.10, 0.13, 0.080, 0.88)
	style.border_color = Color(0.82, 0.58, 0.20, 0.70) if affordable else Color(0.46, 0.36, 0.22, 0.48)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _category_name(id: String) -> String:
	match id:
		"survival":
			return "生存"
		"mining":
			return "挖掘"
		"mobility":
			return "移动"
		_:
			return "通用"

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
