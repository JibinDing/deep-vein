extends Control

var upgrades := {
	"backpack_size": {
		"name": "背包扩容",
		"costs": [200, 350, 500, 800, 1200],
		"description": "背包容量 +2"
	},
	"lantern_duration": {
		"name": "灯具改良",
		"costs": [150, 280, 420, 650, 1000],
		"description": "矿灯上限 +20"
	},
	"mine_speed": {
		"name": "镐头强化",
		"costs": [300, 480, 700, 1000, 1500],
		"description": "挖掘速度 +15%"
	},
	"mine_power": {
		"name": "破岩强化",
		"costs": [500, 900, 1500],
		"description": "挖掘力量 +1"
	}
}

var gold_label: Label
var upgrades_box: HBoxContainer

func _ready() -> void:
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.045, 0.035)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "营地"
	title.position = Vector2(48, 36)
	title.add_theme_font_size_override("font_size", 38)
	add_child(title)

	gold_label = Label.new()
	gold_label.position = Vector2(940, 42)
	gold_label.add_theme_font_size_override("font_size", 22)
	add_child(gold_label)

	var start_button := Button.new()
	start_button.text = "下矿"
	start_button.position = Vector2(1040, 600)
	start_button.custom_minimum_size = Vector2(160, 54)
	start_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))
	add_child(start_button)

	upgrades_box = HBoxContainer.new()
	upgrades_box.position = Vector2(90, 445)
	upgrades_box.add_theme_constant_override("separation", 18)
	add_child(upgrades_box)

	var hint := Label.new()
	hint.text = "MVP 骨架：先验证采矿循环，后续再替换成参考图的手绘 UI。"
	hint.position = Vector2(90, 385)
	hint.modulate = Color(0.78, 0.67, 0.45)
	add_child(hint)

func _refresh() -> void:
	gold_label.text = "金币 %d" % SaveManager.data["total_gold"]
	for child in upgrades_box.get_children():
		child.queue_free()
	for id: String in upgrades.keys():
		upgrades_box.add_child(_make_upgrade_card(id))

func _make_upgrade_card(id: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(210, 150)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var info: Dictionary = upgrades[id]
	var level := SaveManager.get_upgrade_level(id)
	var costs: Array = info["costs"]
	var maxed := level >= costs.size()

	var title := Label.new()
	title.text = "%s %d/%d" % [info["name"], level, costs.size()]
	box.add_child(title)

	var desc := Label.new()
	desc.text = info["description"]
	box.add_child(desc)

	var button := Button.new()
	button.text = "已满级" if maxed else "升级 %d 金币" % costs[level]
	button.disabled = maxed or SaveManager.data["total_gold"] < costs[level]
	button.pressed.connect(func():
		if SaveManager.spend_gold(costs[level]):
			SaveManager.set_upgrade_level(id, level + 1)
			_refresh()
	)
	box.add_child(button)

	return card
