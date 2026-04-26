extends CanvasLayer
class_name HUD

const LANTERN_ICON_PATH := "res://Art/ui/clean/icon_lantern_oil.png"
const BACKPACK_ICON_PATH := "res://Art/ui/clean/icon_backpack.png"
const GOLD_ICON_PATH := "res://Art/ui/clean/icon_gold_coin.png"

var lantern_bar: ProgressBar
var lantern_time_label: Label
var backpack_bar: ProgressBar
var backpack_weight_label: Label
var depth_label: Label
var gold_label: Label
var backpack_list: VBoxContainer
var warning_label: Label
var dynamite_label: Label
var probe_label: Label
var hud_panel_style: StyleBoxFlat

func _ready() -> void:
	hud_panel_style = _make_panel_style()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var resource_panel := PanelContainer.new()
	resource_panel.position = Vector2(16, 16)
	resource_panel.custom_minimum_size = Vector2(316, 142)
	resource_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resource_panel.add_theme_stylebox_override("panel", hud_panel_style)
	root.add_child(resource_panel)

	var top_left := VBoxContainer.new()
	top_left.add_theme_constant_override("separation", 8)
	top_left.custom_minimum_size = Vector2(260, 120)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resource_panel.add_child(top_left)

	var lantern_result := _add_meter_with_label(top_left, LANTERN_ICON_PATH, Vector2(34, 34))
	lantern_bar = lantern_result[0]
	lantern_time_label = lantern_result[1]
	lantern_time_label.text = "--:--"
	var bp_result := _add_meter_with_label(top_left, BACKPACK_ICON_PATH, Vector2(34, 34))
	backpack_bar = bp_result[0]
	backpack_weight_label = bp_result[1]

	warning_label = Label.new()
	warning_label.text = ""
	warning_label.modulate = Color(1.0, 0.38, 0.28)
	top_left.add_child(warning_label)

	dynamite_label = Label.new()
	dynamite_label.text = ""
	dynamite_label.add_theme_font_size_override("font_size", 13)
	dynamite_label.visible = false
	top_left.add_child(dynamite_label)

	probe_label = Label.new()
	probe_label.text = ""
	probe_label.add_theme_font_size_override("font_size", 13)
	probe_label.visible = false
	top_left.add_child(probe_label)

	var right_panel := PanelContainer.new()
	right_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_panel.offset_left = -210
	right_panel.offset_top = 18
	right_panel.offset_right = -18
	right_panel.offset_bottom = 300
	right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_theme_stylebox_override("panel", hud_panel_style)
	root.add_child(right_panel)

	backpack_list = VBoxContainer.new()
	backpack_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backpack_list.add_theme_constant_override("separation", 8)
	backpack_list.custom_minimum_size = Vector2(166, 238)
	right_panel.add_child(backpack_list)
	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_theme_constant_override("separation", 8)
	backpack_list.add_child(title_row)
	var backpack_icon := _make_icon(BACKPACK_ICON_PATH, Vector2(30, 30))
	title_row.add_child(backpack_icon)
	var title := Label.new()
	title.text = "背包"
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title)

	depth_label = Label.new()
	depth_label.position = Vector2(18, 666)
	depth_label.text = "深度 0m"
	root.add_child(depth_label)

	gold_label = Label.new()

func update_lantern(current: float, max_value: float, remaining_secs: float = -1.0) -> void:
	lantern_bar.max_value = max_value
	lantern_bar.value = current
	if remaining_secs >= 0.0:
		var secs := int(remaining_secs)
		lantern_time_label.text = "%02d:%02d" % [secs / 60, secs % 60]
		if remaining_secs < 20.0:
			lantern_time_label.modulate = Color(1.0, 0.30, 0.22)
			warning_label.text = "灯光微弱，尽快撤离"
		else:
			lantern_time_label.modulate = Color(0.85, 0.78, 0.55)
			warning_label.text = ""

func update_backpack(backpack) -> void:
	backpack_bar.max_value = backpack.max_weight
	backpack_bar.value = backpack.current_weight
	backpack_weight_label.text = "%.1fkg / %.0fkg" % [backpack.current_weight, backpack.max_weight]
	for child in backpack_list.get_children():
		if child is HBoxContainer:
			child.queue_free()
	for ore_id: String in backpack.contents.keys():
		var ore = OreDatabase.get_ore(ore_id)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)
		backpack_list.add_child(row)
		var icon_tex := _load_png_texture("res://Art/ui/resource_icon/icon_%s.png" % ore_id)
		if icon_tex != null:
			var icon := TextureRect.new()
			icon.texture = icon_tex
			icon.custom_minimum_size = Vector2(20, 20)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
		var label := Label.new()
		label.text = "%s x%d" % [ore.ore_name if ore != null else ore_id, backpack.contents[ore_id]]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)

func update_depth(depth: int) -> void:
	depth_label.text = "深度 %dm" % depth

func update_dynamite(charges: int, active: bool) -> void:
	if charges <= 0 and not active:
		dynamite_label.visible = false
		return
	dynamite_label.visible = true
	dynamite_label.text = "炸药 ×%d  [F]" % charges if not active else "💥 炸药模式  [点击放置]"
	dynamite_label.modulate = Color(1.0, 0.55, 0.10) if active else Color(0.82, 0.70, 0.46)

func update_dynamite_countdown(secs: int) -> void:
	dynamite_label.visible = secs >= 0
	if secs >= 0:
		dynamite_label.text = "💣 引爆倒计时  %ds" % secs
		dynamite_label.modulate = Color(1.0, 0.25, 0.10) if secs <= 2 else Color(1.0, 0.60, 0.15)

func update_probe(charges: int, active: bool) -> void:
	if charges <= 0:
		probe_label.visible = false
		return
	probe_label.visible = true
	probe_label.text = "探矿锤 ×%d  [G]" % charges if not active else "🔍 探矿模式  [点击探测]"
	probe_label.modulate = Color(0.40, 0.85, 1.0) if active else Color(0.82, 0.70, 0.46)

func update_gold(amount: int) -> void:
	gold_label.text = "%d" % amount

func show_backpack_full() -> void:
	warning_label.text = "背包已满"

func _add_meter_with_label(parent: VBoxContainer, icon_path: String, icon_size: Vector2) -> Array:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	row.add_child(_make_icon(icon_path, icon_size))

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.custom_minimum_size = Vector2(220, 46)
	row.add_child(column)

	var weight_lbl := Label.new()
	weight_lbl.text = "0kg / 10kg"
	weight_lbl.add_theme_font_size_override("font_size", 13)
	column.add_child(weight_lbl)

	var bar := ProgressBar.new()
	bar.max_value = 10.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(220, 14)
	column.add_child(bar)
	return [bar, weight_lbl]

func _add_meter(parent: VBoxContainer, icon_path: String, label_text: String, initial_value: float, icon_size: Vector2) -> ProgressBar:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var icon := _make_icon(icon_path, icon_size)
	row.add_child(icon)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.custom_minimum_size = Vector2(220, 46)
	row.add_child(column)

	var label := Label.new()
	label.text = label_text
	column.add_child(label)

	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value = initial_value
	bar.custom_minimum_size = Vector2(220, 18)
	column.add_child(bar)
	return bar

func _make_icon(path: String, size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = size
	icon.size = size
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _load_png_texture(path)
	if icon.texture == null:
		icon.modulate = Color(1.0, 0.2, 0.2)
	else:
		icon.modulate = Color(1.18, 1.08, 0.88, 1.0)
	return icon

func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.145, 0.09, 0.88)
	style.border_color = Color(0.78, 0.55, 0.20, 0.58)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
