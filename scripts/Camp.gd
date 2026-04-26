extends Control

const CAMP_BACKGROUND_PATH := "res://Art/ui/camp.png"
const GOLD_ICON_PATH := "res://Art/ui/clean/icon_gold_coin.png"

var gold_label: Label

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
	bg_overlay.color = Color(0.02, 0.018, 0.014, 0.28)
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)

	var title := Label.new()
	title.text = "营地"
	title.position = Vector2(48, 36)
	title.add_theme_font_size_override("font_size", 42)
	add_child(title)

	var depth_label := Label.new()
	depth_label.text = "最深 %dm" % int(SaveManager.data["deepest_depth"])
	depth_label.position = Vector2(52, 92)
	depth_label.modulate = Color(0.82, 0.70, 0.48)
	add_child(depth_label)

	var gold_row := HBoxContainer.new()
	gold_row.position = Vector2(990, 42)
	gold_row.add_theme_constant_override("separation", 8)
	add_child(gold_row)
	gold_row.add_child(_make_icon(GOLD_ICON_PATH, Vector2(30, 30)))
	gold_label = Label.new()
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 22)
	gold_row.add_child(gold_label)

	var button_column := VBoxContainer.new()
	button_column.position = Vector2(960, 430)
	button_column.add_theme_constant_override("separation", 14)
	add_child(button_column)

	var start_button := Button.new()
	start_button.text = "下矿"
	start_button.custom_minimum_size = Vector2(190, 56)
	start_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LoadoutScreen.tscn"))
	button_column.add_child(start_button)

	var upgrade_button := Button.new()
	upgrade_button.text = "科技工坊"
	upgrade_button.custom_minimum_size = Vector2(190, 52)
	upgrade_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/TechWorkshop.tscn"))
	button_column.add_child(upgrade_button)

	var warehouse_button := Button.new()
	warehouse_button.text = "仓库"
	warehouse_button.custom_minimum_size = Vector2(190, 52)
	warehouse_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/WarehouseScreen.tscn"))
	button_column.add_child(warehouse_button)

	var merchant_button := Button.new()
	merchant_button.text = "商人"
	merchant_button.custom_minimum_size = Vector2(190, 52)
	merchant_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MerchantScreen.tscn"))
	button_column.add_child(merchant_button)

	var log_label := Label.new()
	log_label.text = "准备好装备后进入矿洞。升级可以在工坊中完成。"
	log_label.position = Vector2(52, 640)
	log_label.modulate = Color(0.78, 0.68, 0.48)
	add_child(log_label)

func _refresh() -> void:
	gold_label.text = "%d" % SaveManager.data["total_gold"]

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
