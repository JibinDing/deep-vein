extends Node
class_name LanternSystem

signal changed(current: float, max_value: float)
signal depleted

var max_lantern := 100.0
var current_lantern := 100.0
var time_depletion_rate := 0.8
var mine_depletion_cost := 1.5
var move_depletion_cost := 0.1
var is_depleted := false

func _process(delta: float) -> void:
	if is_depleted:
		return
	drain(time_depletion_rate * delta)

func on_mine_action() -> void:
	drain(mine_depletion_cost)

func on_move_step() -> void:
	drain(move_depletion_cost)

func drain(amount: float) -> void:
	current_lantern = max(0.0, current_lantern - amount)
	changed.emit(current_lantern, max_lantern)
	if current_lantern <= 0.0 and not is_depleted:
		is_depleted = true
		depleted.emit()

func get_pct() -> float:
	return current_lantern / max_lantern
