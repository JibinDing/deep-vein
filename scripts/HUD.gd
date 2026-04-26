extends CanvasLayer
class_name HUD

var lantern_bar: ProgressBar
var backpack_bar: ProgressBar
var depth_label: Label
var gold_label: Label
var backpack_list: VBoxContainer
var warning_label: Label

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top_left := VBoxContainer.new()
	top_left.position = Vector2(18, 16)
	top_left.custom_minimum_size = Vector2(260, 120)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_left)

	var lantern_label := Label.new()
	lantern_label.text = "煤油灯"
	top_left.add_child(lantern_label)
	lantern_bar = ProgressBar.new()
	lantern_bar.max_value = 100.0
	lantern_bar.value = 100.0
	top_left.add_child(lantern_bar)

	var backpack_label := Label.new()
	backpack_label.text = "背包重量"
	top_left.add_child(backpack_label)
	backpack_bar = ProgressBar.new()
	backpack_bar.max_value = 100.0
	backpack_bar.value = 0.0
	top_left.add_child(backpack_bar)

	warning_label = Label.new()
	warning_label.text = ""
	warning_label.modulate = Color(1.0, 0.38, 0.28)
	top_left.add_child(warning_label)

	var right_panel := PanelContainer.new()
	right_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_panel.offset_left = -190
	right_panel.offset_top = 18
	right_panel.offset_right = -18
	right_panel.offset_bottom = 280
	right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right_panel)

	backpack_list = VBoxContainer.new()
	backpack_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_child(backpack_list)
	var title := Label.new()
	title.text = "背包"
	backpack_list.add_child(title)

	depth_label = Label.new()
	depth_label.position = Vector2(18, 666)
	depth_label.text = "深度 0m"
	root.add_child(depth_label)

	gold_label = Label.new()
	gold_label.position = Vector2(1080, 666)
	gold_label.text = "金币 0"
	root.add_child(gold_label)

func update_lantern(current: float, max_value: float) -> void:
	lantern_bar.max_value = max_value
	lantern_bar.value = current
	if current / max_value < 0.2:
		warning_label.text = "灯光微弱，尽快撤离"

func update_backpack(backpack) -> void:
	backpack_bar.value = backpack.get_fill_pct() * 100.0
	for child in backpack_list.get_children():
		if child is Label and child.text != "背包":
			child.queue_free()
	for ore_id: String in backpack.contents.keys():
		var ore = OreDatabase.get_ore(ore_id)
		var row := Label.new()
		row.text = "%s x%d" % [ore.ore_name if ore != null else ore_id, backpack.contents[ore_id]]
		backpack_list.add_child(row)

func update_depth(depth: int) -> void:
	depth_label.text = "深度 %dm" % depth

func update_gold(amount: int) -> void:
	gold_label.text = "本次金币 %d" % amount

func show_backpack_full() -> void:
	warning_label.text = "背包已满"
