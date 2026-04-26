extends Resource
class_name OreData

@export var ore_id: String = ""
@export var ore_name: String = ""
@export var base_value: int = 0
@export var weight: float = 1.0
@export_range(0.0, 1.0) var rarity: float = 0.1
@export var depth_min: int = 0
@export var glow_color: Color = Color.WHITE
@export var era_required: String = "candle"
