extends Control

const GOLD_ICON_PATH := "res://Art/ui/clean/icon_gold_coin.png"
const CAMP_BG_PATH := "res://Art/ui/camp.png"

var loadout: Array = []
var slot_buttons: Array = []
var item_buttons: Dictionary = {}
var selected_slot: int = -1

var backpack_preview: Label
var lantern_preview: Label

func _ready() -> void:
	loadout = EquipmentDatabase.get_loadout()
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var bg_texture := TextureRect.new()
	bg_texture.texture = _load_png_texture(CAMP_BG_PATH)
	bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_texture)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.018, 0.014, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "出发准备"
	title.position = Vector2(72, 44)
	title.add_theme_font_size_override("font_size", 42)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "选择携带的装备，装备会占用背包重量。"
	subtitle.position = Vector2(76, 102)
	subtitle.modulate = Color(0.80, 0.70, 0.48)
	add_child(subtitle)

	# ── 左侧：装备槽 ──
	var slots_title := Label.new()
	slots_title.text = "装备槽"
	slots_title.position = Vector2(72, 148)
	slots_title.add_theme_font_size_override("font_size", 22)
	add_child(slots_title)

	var slots_col := VBoxContainer.new()
	slots_col.position = Vector2(72, 186)
	slots_col.add_theme_constant_override("separation", 12)
	add_child(slots_col)

	var slot_count := EquipmentDatabase.get_loadout_slot_count()
	for i in range(slot_count):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(300, 62)
		btn.pressed.connect(func(idx = i): _on_slot_clicked(idx))
		slots_col.add_child(btn)
		slot_buttons.append(btn)

	# ── 预览面板 ──
	var preview_panel := PanelContainer.new()
	preview_panel.position = Vector2(72, 520)
	preview_panel.custom_minimum_size = Vector2(300, 90)
	preview_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(preview_panel)

	var preview_col := VBoxContainer.new()
	preview_col.add_theme_constant_override("separation", 6)
	preview_panel.add_child(preview_col)

	backpack_preview = Label.new()
	backpack_preview.add_theme_font_size_override("font_size", 16)
	preview_col.add_child(backpack_preview)

	lantern_preview = Label.new()
	lantern_preview.add_theme_font_size_override("font_size", 16)
	preview_col.add_child(lantern_preview)

	# ── 右侧：可选装备 ──
	var items_title := Label.new()
	items_title.text = "可携带装备"
	items_title.position = Vector2(500, 148)
	items_title.add_theme_font_size_override("font_size", 22)
	add_child(items_title)

	var items_col := VBoxContainer.new()
	items_col.position = Vector2(500, 186)
	items_col.add_theme_constant_override("separation", 12)
	add_child(items_col)

	for item_id in EquipmentDatabase.get_all_ids():
		var row := _make_item_row(item_id)
		items_col.add_child(row)

	# ── 底部按钮 ──
	var back_btn := Button.new()
	back_btn.text = "返回营地"
	back_btn.position = Vector2(72, 640)
	back_btn.custom_minimum_size = Vector2(180, 48)
	back_btn.pressed.connect(func():
		EquipmentDatabase.save_loadout(loadout)
		get_tree().change_scene_to_file("res://scenes/Camp.tscn")
	)
	add_child(back_btn)

	var go_btn := Button.new()
	go_btn.text = "▶  下矿出发"
	go_btn.position = Vector2(1040, 640)
	go_btn.custom_minimum_size = Vector2(200, 48)
	go_btn.pressed.connect(func():
		EquipmentDatabase.save_loadout(loadout)
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	)
	add_child(go_btn)

func _make_item_row(item_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(660, 72)
	panel.add_theme_stylebox_override("panel", _make_panel_style())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var info_col := VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 2)
	row.add_child(info_col)

	var item := EquipmentDatabase.get_item(item_id)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info_col.add_child(name_row)

	var name_label := Label.new()
	name_label.text = String(item.get("name", item_id))
	name_label.add_theme_font_size_override("font_size", 18)
	name_row.add_child(name_label)

	var weight_label := Label.new()
	weight_label.text = "%.1f kg" % float(item.get("weight", 0))
	weight_label.modulate = Color(0.75, 0.60, 0.35)
	weight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_row.add_child(weight_label)

	var desc_label := Label.new()
	desc_label.text = String(item.get("description", ""))
	desc_label.modulate = Color(0.72, 0.65, 0.50)
	desc_label.add_theme_font_size_override("font_size", 14)
	info_col.add_child(desc_label)

	var owned := EquipmentDatabase.get_owned_count(item_id)
	var equip_count := loadout.count(item_id)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(88, 38)
	btn.pressed.connect(func(): _on_item_equip(item_id))
	row.add_child(btn)
	item_buttons[item_id] = btn

	return panel

func _on_slot_clicked(idx: int) -> void:
	if loadout[idx] != "":
		loadout[idx] = ""
		selected_slot = -1
	else:
		selected_slot = idx
	_refresh()

func _on_item_equip(item_id: String) -> void:
	var owned := EquipmentDatabase.get_owned_count(item_id)
	var equip_count := loadout.count(item_id)

	if equip_count >= owned:
		return

	if selected_slot >= 0 and selected_slot < loadout.size():
		loadout[selected_slot] = item_id
		selected_slot = -1
		_refresh()
		return

	for i in range(loadout.size()):
		if loadout[i] == "":
			loadout[i] = item_id
			_refresh()
			return

func _refresh() -> void:
	var slot_count := EquipmentDatabase.get_loadout_slot_count()
	for i in range(slot_button_count()):
		var btn: Button = slot_buttons[i]
		var item_id: String = loadout[i] if i < loadout.size() else ""
		if item_id != "":
			var item := EquipmentDatabase.get_item(item_id)
			btn.text = "[ %s  %.1f kg ]" % [item.get("name", item_id), float(item.get("weight", 0))]
		else:
			if selected_slot == i:
				btn.text = "← 点击右侧装备放入此槽"
			else:
				btn.text = "[ 空槽 ]"

	for item_id in item_buttons.keys():
		var btn: Button = item_buttons[item_id]
		var owned := EquipmentDatabase.get_owned_count(item_id)
		var equip_count := loadout.count(item_id)
		var available := owned - equip_count
		btn.text = "装备 (%d)" % available
		btn.disabled = available <= 0

	var stats := UpgradeDatabase.get_session_stats()
	var effects := EquipmentDatabase.get_loadout_effects()
	var load_weight := EquipmentDatabase.get_loadout_weight()
	var effective_backpack: float = float(stats["backpack_max_weight"]) + float(effects.get("backpack_bonus", 0.0)) - load_weight
	var effective_lantern: float = float(stats["lantern_max"]) + float(effects.get("lantern_bonus", 0.0))
	backpack_preview.text = "有效背包容量：%.1f / %.1f（装备占用 %.1f）" % [
		effective_backpack,
		float(stats["backpack_max_weight"]) + float(effects.get("backpack_bonus", 0.0)),
		load_weight
	]
	lantern_preview.text = "矿灯上限：%.0f" % effective_lantern

func slot_button_count() -> int:
	return slot_buttons.size()

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.11, 0.07, 0.88)
	style.border_color = Color(0.62, 0.46, 0.20, 0.50)
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
