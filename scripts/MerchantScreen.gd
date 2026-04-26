extends Control

const GOLD_ICON_PATH := "res://Art/ui/clean/icon_gold_coin.png"
const RESOURCE_ICON_DIR := "res://Art/ui/resource_icon/"

var gold_label: Label
var sell_panel: Control
var buy_panel: Control
var tab_sell_btn: Button
var tab_buy_btn: Button
var ore_list: VBoxContainer
var equip_list: VBoxContainer

func _ready() -> void:
	_build_ui()
	_show_tab("sell")
	_refresh()

func _build_ui() -> void:
	var bg_texture := TextureRect.new()
	bg_texture.texture = _load_png_texture("res://Art/ui/merchant.png")
	bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_texture)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.018, 0.014, 0.45)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── 顶栏：标题 + 金币 ──
	var title := Label.new()
	title.text = "商人"
	title.position = Vector2(72, 28)
	title.add_theme_font_size_override("font_size", 42)
	add_child(title)

	var gold_row := HBoxContainer.new()
	gold_row.position = Vector2(1050, 36)
	gold_row.add_theme_constant_override("separation", 8)
	add_child(gold_row)
	gold_row.add_child(_make_icon(GOLD_ICON_PATH, Vector2(28, 28)))
	gold_label = Label.new()
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 22)
	gold_row.add_child(gold_label)

	# ── 出售面板 ──
	sell_panel = Control.new()
	sell_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	sell_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sell_panel)

	ore_list = VBoxContainer.new()
	ore_list.position = Vector2(72, 152)
	ore_list.add_theme_constant_override("separation", 10)
	sell_panel.add_child(ore_list)

	var sell_all_btn := Button.new()
	sell_all_btn.text = "全部出售"
	sell_all_btn.position = Vector2(1060, 630)
	sell_all_btn.custom_minimum_size = Vector2(168, 48)
	sell_all_btn.pressed.connect(_on_sell_all)
	sell_panel.add_child(sell_all_btn)

	# ── 购买面板 ──
	buy_panel = Control.new()
	buy_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	buy_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(buy_panel)

	equip_list = VBoxContainer.new()
	equip_list.position = Vector2(72, 152)
	equip_list.add_theme_constant_override("separation", 10)
	buy_panel.add_child(equip_list)

	# ── Tab 按钮（在面板之后添加，确保在最上层接收点击）──
	var tab_row := HBoxContainer.new()
	tab_row.position = Vector2(72, 92)
	tab_row.add_theme_constant_override("separation", 0)
	add_child(tab_row)

	tab_sell_btn = Button.new()
	tab_sell_btn.text = "出售矿石"
	tab_sell_btn.custom_minimum_size = Vector2(160, 42)
	tab_sell_btn.pressed.connect(func(): _show_tab("sell"))
	tab_row.add_child(tab_sell_btn)

	tab_buy_btn = Button.new()
	tab_buy_btn.text = "购买装备"
	tab_buy_btn.custom_minimum_size = Vector2(160, 42)
	tab_buy_btn.pressed.connect(func(): _show_tab("buy"))
	tab_row.add_child(tab_buy_btn)

	# ── 返回按钮 ──
	var back_btn := Button.new()
	back_btn.text = "返回营地"
	back_btn.position = Vector2(72, 630)
	back_btn.custom_minimum_size = Vector2(168, 48)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Camp.tscn"))
	add_child(back_btn)

func _show_tab(tab: String) -> void:
	sell_panel.visible = tab == "sell"
	buy_panel.visible = tab == "buy"
	tab_sell_btn.disabled = tab == "sell"
	tab_buy_btn.disabled = tab == "buy"

func _refresh() -> void:
	gold_label.text = "%d" % SaveManager.data["total_gold"]
	_refresh_sell()
	_refresh_buy()

func _refresh_sell() -> void:
	for child in ore_list.get_children():
		child.queue_free()

	var warehouse := SaveManager.get_warehouse()
	if warehouse.is_empty():
		var empty := Label.new()
		empty.text = "仓库空空如也，先去下矿带些矿石回来。"
		empty.modulate = Color(0.62, 0.52, 0.36)
		empty.add_theme_font_size_override("font_size", 20)
		ore_list.add_child(empty)
		return

	for ore_id: String in warehouse.keys():
		var count := int(warehouse[ore_id])
		var ore = OreDatabase.get_ore(ore_id)
		if ore == null:
			continue
		ore_list.add_child(_make_ore_row(ore_id, ore, count))

func _refresh_buy() -> void:
	for child in equip_list.get_children():
		child.queue_free()
	for item_id in EquipmentDatabase.get_all_ids():
		equip_list.add_child(_make_equip_row(item_id))

func _make_ore_row(ore_id: String, ore, count: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1100, 64)
	panel.add_theme_stylebox_override("panel", _make_card_style(Color(0.14, 0.11, 0.07, 0.92), Color(0.62, 0.46, 0.20, 0.50)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)

	var icon_tex := _load_png_texture(RESOURCE_ICON_DIR + "icon_%s.png" % ore_id)
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

	var name_label := Label.new()
	name_label.text = ore.ore_name
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	row.add_child(name_label)

	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.custom_minimum_size = Vector2(60, 0)
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.modulate = Color(0.82, 0.72, 0.50)
	count_label.add_theme_font_size_override("font_size", 18)
	row.add_child(count_label)

	var price_row := HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 4)
	price_row.custom_minimum_size = Vector2(160, 0)
	row.add_child(price_row)
	price_row.add_child(_make_icon(GOLD_ICON_PATH, Vector2(20, 20)))
	var price_label := Label.new()
	price_label.text = "%d / 个" % ore.base_value
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.modulate = Color(1.0, 0.82, 0.32)
	price_label.add_theme_font_size_override("font_size", 16)
	price_row.add_child(price_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var sell_one_btn := Button.new()
	sell_one_btn.text = "卖 1"
	sell_one_btn.custom_minimum_size = Vector2(72, 36)
	sell_one_btn.pressed.connect(func(): _sell(ore_id, 1))
	row.add_child(sell_one_btn)

	var sell_all_btn := Button.new()
	sell_all_btn.text = "全卖  +%d" % (ore.base_value * count)
	sell_all_btn.custom_minimum_size = Vector2(130, 36)
	sell_all_btn.pressed.connect(func(): _sell(ore_id, count))
	row.add_child(sell_all_btn)

	return panel

func _make_equip_row(item_id: String) -> PanelContainer:
	var item := EquipmentDatabase.get_item(item_id)
	var owned := EquipmentDatabase.get_owned_count(item_id)
	var price := int(item.get("buy_price", 0))
	var can_afford: bool = int(SaveManager.data["total_gold"]) >= price

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1100, 72)
	panel.add_theme_stylebox_override("panel", _make_card_style(Color(0.12, 0.10, 0.07, 0.90), Color(0.55, 0.40, 0.18, 0.45)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	info.add_child(name_row)

	var name_label := Label.new()
	name_label.text = String(item.get("name", item_id))
	name_label.add_theme_font_size_override("font_size", 19)
	name_row.add_child(name_label)

	var weight_label := Label.new()
	weight_label.text = "%.1f kg" % float(item.get("weight", 0))
	weight_label.modulate = Color(0.72, 0.58, 0.32)
	weight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_row.add_child(weight_label)

	var desc_label := Label.new()
	desc_label.text = String(item.get("description", ""))
	desc_label.modulate = Color(0.70, 0.63, 0.48)
	desc_label.add_theme_font_size_override("font_size", 14)
	info.add_child(desc_label)

	var owned_label := Label.new()
	owned_label.text = "已拥有 %d 个" % owned
	owned_label.modulate = Color(0.65, 0.75, 0.55)
	owned_label.add_theme_font_size_override("font_size", 13)
	info.add_child(owned_label)

	var buy_col := VBoxContainer.new()
	buy_col.add_theme_constant_override("separation", 4)
	buy_col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(buy_col)

	var price_row := HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 4)
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	buy_col.add_child(price_row)
	price_row.add_child(_make_icon(GOLD_ICON_PATH, Vector2(18, 18)))
	var price_label := Label.new()
	price_label.text = "%d" % price
	price_label.modulate = Color(1.0, 0.82, 0.32)
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_row.add_child(price_label)

	var buy_btn := Button.new()
	buy_btn.text = "购买"
	buy_btn.custom_minimum_size = Vector2(100, 36)
	buy_btn.disabled = not can_afford
	buy_btn.pressed.connect(func():
		if EquipmentDatabase.buy(item_id):
			_refresh()
	)
	buy_col.add_child(buy_btn)

	return panel

func _sell(ore_id: String, amount: int) -> void:
	var warehouse := SaveManager.get_warehouse()
	var available := int(warehouse.get(ore_id, 0))
	var actual: int = min(amount, available)
	if actual <= 0:
		return
	var ore = OreDatabase.get_ore(ore_id)
	if ore == null:
		return
	var gold: int = int(ore.base_value) * actual
	if actual >= available:
		SaveManager.data["warehouse"].erase(ore_id)
	else:
		SaveManager.data["warehouse"][ore_id] = available - actual
	SaveManager.add_gold(gold)
	_refresh()

func _on_sell_all() -> void:
	var warehouse := SaveManager.get_warehouse().duplicate()
	for ore_id: String in warehouse.keys():
		_sell(ore_id, int(warehouse[ore_id]))

func _make_card_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _make_icon(path: String, size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_png_texture(path)
	return icon

func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
