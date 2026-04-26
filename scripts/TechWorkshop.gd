extends Control

const GOLD_ICON_PATH := "res://Art/ui/clean/icon_gold_coin.png"

# ── 布局常量 ──
const CANVAS_W   := 1240.0
const ERA_W      := 360.0
const ERA_H      := 78.0
const CARD_W     := 242.0
const CARD_H     := 136.0
const CARD_GAP   := 14.0
const V_STEM     := 38.0   # 时代节点到横轨的距离
const V_DROP     := 4.0    # 横轨到卡片顶部的小间隙
const V_COLLECT  := 50.0   # 卡片底部到下方汇聚横轨的距离
const MARGIN_X   := 20.0

const ERA_ACCENT := {
	"candle":   Color(0.90, 0.68, 0.22),
	"gas_lamp": Color(0.42, 0.80, 0.60),
	"electric": Color(0.45, 0.65, 1.00)
}
const LINE_COLOR := Color(0.58, 0.46, 0.26, 0.80)
const LINE_W     := 2.0

var gold_label: Label

# 用于画线的内部画布
class TreeCanvas extends Control:
	var segs: Array = []
	var line_color := Color(0.58, 0.46, 0.26, 0.80)
	var line_w     := 2.0
	func _draw() -> void:
		for s in segs:
			draw_line(s[0], s[1], line_color, line_w, true)

var canvas: TreeCanvas
var _refresh_pending := false

func _ready() -> void:
	_build_chrome()
	_build_tree()

# ── 顶部导航栏（始终显示，在滚动区上方）──
func _build_chrome() -> void:
	var bg_tex := TextureRect.new()
	bg_tex.texture = _load_png("res://Art/ui/camp.png")
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_tex)

	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.018, 0.014, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var title := Label.new()
	title.text = "科技工坊"
	title.position = Vector2(72, 12)
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)

	var gold_row := HBoxContainer.new()
	gold_row.position = Vector2(1070, 16)
	gold_row.add_theme_constant_override("separation", 8)
	add_child(gold_row)
	gold_row.add_child(_icon(GOLD_ICON_PATH, Vector2(24, 24)))
	gold_label = Label.new()
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_row.add_child(gold_label)

	var back := Button.new()
	back.text = "返回营地"
	back.position = Vector2(72, 672)
	back.custom_minimum_size = Vector2(160, 42)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Camp.tscn"))
	add_child(back)

# ── 构建可滚动科技树 ──
func _build_tree() -> void:
	gold_label.text = "%d" % int(SaveManager.data["total_gold"])

	var scroll := ScrollContainer.new()
	scroll.position  = Vector2(20, 60)
	scroll.size      = Vector2(1240, 604)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	canvas = TreeCanvas.new()
	canvas.custom_minimum_size = Vector2(CANVAS_W, 820)
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(canvas)

	_build_tree_content()

# ── 工具：计算 n 张卡片的中心 X 列表 ──
func _card_centers(n: int) -> Array:
	if n == 0:
		return []
	var total_w: float = n * CARD_W + (n - 1) * CARD_GAP
	var start_x: float = (CANVAS_W - total_w) * 0.5 + CARD_W * 0.5
	var result: Array = []
	for i in range(n):
		result.append(start_x + i * (CARD_W + CARD_GAP))
	return result

func _add_line(a: Vector2, b: Vector2) -> void:
	canvas.segs.append([a, b])

func _add_hline(centers: Array, y: float) -> void:
	if centers.size() < 2:
		return
	canvas.segs.append([Vector2(centers[0], y), Vector2(centers[-1], y)])

# ── 时代节点 ──
func _place_era_node(era_id: String, cx: float, y: float, unlocked: bool, unlock_hint: String) -> void:
	var accent: Color = ERA_ACCENT.get(era_id, Color.WHITE)
	var era    := EraDatabase.get_era(era_id)
	var is_current := era_id == EraDatabase.get_current_era()

	var style := StyleBoxFlat.new()
	style.bg_color     = accent.darkened(0.58) if unlocked else Color(0.07, 0.065, 0.055, 0.92)
	style.border_color = accent if unlocked else Color(0.30, 0.26, 0.20)
	style.set_border_width_all(2)
	style.corner_radius_top_left    = 6
	style.corner_radius_top_right   = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right= 6
	style.content_margin_left   = 18
	style.content_margin_right  = 18
	style.content_margin_top    = 10
	style.content_margin_bottom = 10

	var panel := PanelContainer.new()
	panel.position = Vector2(cx - ERA_W * 0.5, y)
	panel.custom_minimum_size = Vector2(ERA_W, ERA_H)
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	col.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = String(era.get("name", era_id))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.modulate = accent if unlocked else Color(0.48, 0.42, 0.34)
	name_row.add_child(name_lbl)

	var badge := Label.new()
	if is_current:
		badge.text = "▶ 当前"
	elif unlocked:
		badge.text = "✓ 已解锁"
	else:
		badge.text = "🔒"
	badge.add_theme_font_size_override("font_size", 14)
	badge.modulate = accent if unlocked else Color(0.45, 0.40, 0.32)
	name_row.add_child(badge)

	var desc_lbl := Label.new()
	desc_lbl.text = String(era.get("description", ""))
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.modulate = Color(0.72, 0.65, 0.50) if unlocked else Color(0.40, 0.36, 0.28)
	col.add_child(desc_lbl)

	# 解锁按钮行（仅对"下一个可解锁时代"显示）
	if not unlocked and era_id == EraDatabase.get_next_era():
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 12)
		col.add_child(btn_row)

		var hint := Label.new()
		hint.text = unlock_hint
		hint.add_theme_font_size_override("font_size", 12)
		hint.modulate = Color(0.80, 0.68, 0.38)
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_row.add_child(hint)

		var can := EraDatabase.can_unlock_next() == "ok"
		var btn := Button.new()
		btn.text = "解锁"
		btn.custom_minimum_size = Vector2(80, 28)
		btn.disabled = not can
		btn.pressed.connect(func():
			if EraDatabase.unlock_next():
				_refresh()
		)
		btn_row.add_child(btn)

# ── 升级卡片 ──
func _place_upgrade_card(id: String, x: float, y: float, era_unlocked: bool) -> void:
	var info    := UpgradeDatabase.get_upgrade(id)
	var level   := UpgradeDatabase.get_level(id)
	var max_lv  := UpgradeDatabase.get_max_level(id)
	var maxed   := UpgradeDatabase.is_maxed(id)
	var cost    := UpgradeDatabase.get_next_cost(id)
	var can_buy := era_unlocked and UpgradeDatabase.can_purchase(id)

	var style := StyleBoxFlat.new()
	if maxed:
		style.bg_color     = Color(0.10, 0.14, 0.08, 0.92)
		style.border_color = Color(0.40, 0.62, 0.28, 0.60)
	elif can_buy:
		style.bg_color     = Color(0.16, 0.12, 0.07, 0.94)
		style.border_color = Color(0.80, 0.58, 0.20, 0.70)
	elif era_unlocked:
		style.bg_color     = Color(0.09, 0.08, 0.06, 0.88)
		style.border_color = Color(0.38, 0.30, 0.18, 0.45)
	else:
		style.bg_color     = Color(0.06, 0.055, 0.048, 0.80)
		style.border_color = Color(0.24, 0.22, 0.18, 0.30)
	style.set_border_width_all(1)
	style.corner_radius_top_left    = 4
	style.corner_radius_top_right   = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right= 4
	style.content_margin_left   = 12
	style.content_margin_right  = 12
	style.content_margin_top    = 10
	style.content_margin_bottom = 10

	var panel := PanelContainer.new()
	panel.position = Vector2(x, y)
	panel.custom_minimum_size = Vector2(CARD_W, CARD_H)
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	panel.add_child(col)

	# 标题行
	var title_row := HBoxContainer.new()
	col.add_child(title_row)
	var name_lbl := Label.new()
	name_lbl.text = String(info.get("name", id))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.modulate = Color.WHITE if era_unlocked else Color(0.42, 0.38, 0.30)
	title_row.add_child(name_lbl)
	var lv_lbl := Label.new()
	lv_lbl.text = "%d/%d" % [level, max_lv]
	lv_lbl.add_theme_font_size_override("font_size", 13)
	lv_lbl.modulate = Color(0.65, 0.82, 0.48) if maxed else Color(0.68, 0.60, 0.42)
	title_row.add_child(lv_lbl)

	# 进度条
	var bar := ProgressBar.new()
	bar.max_value = max_lv
	bar.value = level
	bar.custom_minimum_size = Vector2(0, 5)
	bar.show_percentage = false
	col.add_child(bar)

	# 描述
	var desc := Label.new()
	desc.text = String(info.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.modulate = Color(0.70, 0.62, 0.46) if era_unlocked else Color(0.36, 0.32, 0.26)
	col.add_child(desc)

	# 按钮
	var btn := Button.new()
	if maxed:
		btn.text = "已满级"
	elif not era_unlocked:
		btn.text = "未解锁"
	else:
		btn.text = "升级  %d" % cost
	btn.disabled = not can_buy
	btn.pressed.connect(func():
		if UpgradeDatabase.purchase(id):
			_refresh()
	)
	col.add_child(btn)

# ── 刷新整棵树 ──
func _refresh() -> void:
	gold_label.text = "%d" % int(SaveManager.data["total_gold"])
	canvas.segs.clear()
	for child in canvas.get_children():
		child.queue_free()
	await get_tree().process_frame
	_build_tree_content()

func _build_tree_content() -> void:
	# 直接重新走 _build_tree 的树构建逻辑（复用）
	var current     := EraDatabase.get_current_era()
	var unlocked_idx := EraDatabase.ERAS.find(current)
	var cx := CANVAS_W * 0.5

	var candle_y  := 16.0
	var bus1_y    := candle_y + ERA_H + V_STEM
	var cards1_y  := bus1_y + V_DROP
	var conv1_y   := cards1_y + CARD_H + V_COLLECT
	var gas_y     := conv1_y + V_STEM
	var bus2_y    := gas_y + ERA_H + V_STEM
	var cards2_y  := bus2_y + V_DROP
	var conv2_y   := cards2_y + CARD_H + V_COLLECT
	var elec_y    := conv2_y + V_STEM

	canvas.custom_minimum_size = Vector2(CANVAS_W, elec_y + ERA_H + 20)

	var c_ids := UpgradeDatabase.get_upgrades_for_era("candle")
	var c_xs  := _card_centers(c_ids.size())
	_place_era_node("candle", cx, candle_y, unlocked_idx >= 0, "")
	_add_line(Vector2(cx, candle_y + ERA_H), Vector2(cx, bus1_y))
	_add_hline(c_xs, bus1_y)
	for i in range(c_ids.size()):
		_add_line(Vector2(c_xs[i], bus1_y), Vector2(c_xs[i], cards1_y))
		_place_upgrade_card(c_ids[i], c_xs[i] - CARD_W * 0.5, cards1_y, unlocked_idx >= 0)
	for i in range(c_ids.size()):
		_add_line(Vector2(c_xs[i], cards1_y + CARD_H), Vector2(c_xs[i], conv1_y))
	_add_hline(c_xs, conv1_y)
	_add_line(Vector2(cx, conv1_y), Vector2(cx, gas_y))

	_place_era_node("gas_lamp", cx, gas_y, unlocked_idx >= 1,
		_unlock_label("gas_lamp") if unlocked_idx < 1 else "")

	var g_ids := UpgradeDatabase.get_upgrades_for_era("gas_lamp")
	var g_xs  := _card_centers(g_ids.size())
	_add_line(Vector2(cx, gas_y + ERA_H), Vector2(cx, bus2_y))
	_add_hline(g_xs, bus2_y)
	for i in range(g_ids.size()):
		_add_line(Vector2(g_xs[i], bus2_y), Vector2(g_xs[i], cards2_y))
		_place_upgrade_card(g_ids[i], g_xs[i] - CARD_W * 0.5, cards2_y, unlocked_idx >= 1)
	for i in range(g_ids.size()):
		_add_line(Vector2(g_xs[i], cards2_y + CARD_H), Vector2(g_xs[i], conv2_y))
	_add_hline(g_xs, conv2_y)
	_add_line(Vector2(cx, conv2_y), Vector2(cx, elec_y))

	_place_era_node("electric", cx, elec_y, unlocked_idx >= 2,
		_unlock_label("electric") if unlocked_idx < 2 else "")

	canvas.queue_redraw()

func _unlock_label(era_id: String) -> String:
	var era  := EraDatabase.get_era(era_id)
	var gold := int(era.get("unlock_gold", 0))
	var ore_req: Dictionary = era.get("unlock_ores", {})
	var parts: Array = ["%d 金" % gold]
	for ore_id in ore_req:
		var ore = OreDatabase.get_ore(ore_id)
		var name: String = ore.ore_name if ore != null else ore_id
		parts.append("%s ×%d" % [name, int(ore_req[ore_id])])
	return "  ".join(parts)

func _icon(path: String, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.custom_minimum_size = size
	t.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture = _load_png(path)
	return t

func _load_png(path: String) -> Texture2D:
	var img := Image.new()
	if img.load(path) != OK:
		return null
	return ImageTexture.create_from_image(img)
