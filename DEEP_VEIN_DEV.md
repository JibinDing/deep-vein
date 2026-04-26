# Deep Vein (深渊金矿) - Development Document for Claude Code

## Project Overview
A roguelike mining game built in **Godot 4** using **GDScript**.
- No combat system
- Core loop: mine → collect → evacuate → upgrade camp → repeat
- Meta progression: tech tree unlocks new eras with different rules
- Build system: tools that change mining rules, not just add numbers

---

## Tech Stack
- **Engine**: Godot 4
- **Language**: GDScript
- **Map**: TileMap (grid-based), each cell is 32x32 or 64x64 pixels
- **Physics**: NO gravity. Player moves freely through any excavated cell
- **Pathfinding**: AStarGrid2D (built-in Godot, grid-optimized)

---

## MVP Scope (Build This First)
Get this running before anything else. No art, placeholder graphics only.

### MVP Checklist
- [ ] Grid map generates with rock cells and ore cells
- [ ] Player clicks a cell → pathfinds and moves there
- [ ] If target cell is rock → player walks to adjacent cell and mines it
- [ ] If target cell is already empty → player walks into it
- [ ] Mining removes rock cell, plays particle effect, shows +value popup
- [ ] Ore cells drop ore item when mined, auto-collected on player contact
- [ ] Backpack has weight limit, fills up as ore collected
- [ ] Lantern resource depletes over time
- [ ] Player can trigger evacuation → walks back to surface entrance
- [ ] Session ends → show results screen with ore collected and gold earned
- [ ] Gold persists between sessions (saved to file)
- [ ] Camp screen: spend gold on basic upgrades (backpack size, lantern duration)
- [ ] "Go Mining" button starts new session

---

## Project Structure
```
res://
├── scenes/
│   ├── Game.tscn          # Main game scene (underground)
│   ├── Camp.tscn          # Camp/meta screen
│   ├── Results.tscn       # End of session results
│   └── UI/
│       ├── HUD.tscn       # In-game HUD (lantern bar, oxygen bar, backpack)
│       └── Backpack.tscn  # Backpack grid UI
├── scripts/
│   ├── Game.gd            # Main game controller
│   ├── MapGenerator.gd    # Procedural map generation
│   ├── Player.gd          # Player movement and actions
│   ├── Pathfinder.gd      # AStarGrid2D wrapper
│   ├── TileManager.gd     # Tile state management
│   ├── OreManager.gd      # Ore spawning and collection
│   ├── Backpack.gd        # Inventory/weight system
│   ├── LanternSystem.gd   # Lantern/oxygen depletion
│   ├── Camp.gd            # Camp upgrades logic
│   ├── SaveManager.gd     # Persistent save data
│   └── ResultsScreen.gd   # Session results display
├── resources/
│   ├── OreData.tres       # Ore type definitions
│   └── UpgradeData.tres   # Camp upgrade definitions
└── assets/
    ├── placeholder/       # Simple colored rectangles for MVP
    └── audio/             # Sound effects
```

---

## Core Data Structures

### Cell Types (TileManager.gd)
```gdscript
enum CellType {
    ROCK,        # Solid, cannot walk through, can mine
    EMPTY,       # Already excavated, player can walk here
    ORE,         # Contains ore, mining reveals ore item
    HARD_ROCK,   # Takes multiple hits to mine
    BLOCKED,     # Cannot be mined (requires tech unlock)
    ENTRANCE,    # Surface entrance, evacuation point
    SPECIAL      # Triggers event when mined
}
```

### Ore Types (OreData.tres)
```gdscript
# Define as Resource
class_name OreData
var ore_id: String
var ore_name: String
var base_value: int       # Gold value per unit
var weight: float         # Backpack weight per unit
var rarity: float         # 0.0 to 1.0, spawn probability
var depth_min: int        # Minimum depth to appear (in cells)
var glow_color: Color     # Self-emission color for visuals
var era_required: String  # Tech era needed to access zone
```

### MVP Ore List
```
coal:    value=5,   weight=1.0, rarity=0.6, depth_min=0
iron:    value=15,  weight=1.5, rarity=0.3, depth_min=10
crystal: value=40,  weight=0.8, rarity=0.15, depth_min=25
gold:    value=100, weight=2.0, rarity=0.05, depth_min=40
```

### Player State (Player.gd)
```gdscript
var grid_position: Vector2i   # Current cell position
var is_moving: bool = false
var is_mining: bool = false
var mine_target: Vector2i     # Cell being mined
var move_speed: float = 4.0   # Cells per second
var mine_speed: float = 1.0   # Hits per second (upgradeable)
var mine_power: int = 1       # Hits needed for normal rock = 1
```

### Session State (Game.gd)
```gdscript
var current_depth: int = 0       # Cells below surface
var session_gold: int = 0        # Gold earned this session
var session_ores: Dictionary = {} # ore_id -> count collected
var is_evacuating: bool = false
```

### Save Data (SaveManager.gd)
```gdscript
var total_gold: int = 0
var upgrades: Dictionary = {}    # upgrade_id -> level
var blueprints_found: Array = [] # blueprint ids discovered
var total_sessions: int = 0
var deepest_reached: int = 0
```

---

## Map Generation (MapGenerator.gd)

### Generation Rules
```
Map size: 40 cells wide x 200 cells tall (MVP)
Cell [x, 0] = ENTRANCE row (surface)
Cells [x, 1-5] = Tutorial zone, mostly ROCK, few COAL
Cells [x, 6+] = Generated zone

Generation per cell:
1. Default: ROCK
2. Roll for ore based on depth and rarity table
3. If ore: set CellType.ORE, store ore_id in metadata
4. Carve pre-made tunnels to ensure map is not completely solid
5. Mark some cells as HARD_ROCK (depth > 20)
6. Mark some cells as BLOCKED (depth > 50, requires tech unlock)
```

### Pre-carved Tunnel System
```
At generation time, carve a main vertical shaft (2 cells wide)
Branch off horizontal tunnels every 10-15 cells
This ensures player always has a path to explore
Random ore pockets off the main tunnels
```

---

## Pathfinding (Pathfinder.gd)

### Setup
```gdscript
var astar: AStarGrid2D

func setup(map_size: Vector2i):
    astar = AStarGrid2D.new()
    astar.region = Rect2i(Vector2i.ZERO, map_size)
    astar.cell_size = Vector2(1, 1)
    astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    astar.update()

func set_cell_walkable(cell: Vector2i, walkable: bool):
    astar.set_point_solid(cell, !walkable)

func get_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
    return astar.get_id_path(from, to)
```

### Click Handling Logic
```gdscript
func handle_click(clicked_cell: Vector2i):
    var cell_type = tile_manager.get_cell_type(clicked_cell)
    
    if cell_type == CellType.EMPTY:
        # Walk there directly
        player.move_to(clicked_cell)
    
    elif cell_type == CellType.ROCK or cell_type == CellType.ORE:
        # Find adjacent empty cell closest to target
        var adjacent = get_adjacent_empty_cell(clicked_cell, player.grid_position)
        if adjacent != Vector2i(-1, -1):
            # Walk to adjacent cell, then mine target
            player.move_then_mine(adjacent, clicked_cell)
    
    elif cell_type == CellType.ENTRANCE:
        # Evacuate
        player.evacuate()

func get_adjacent_empty_cell(target: Vector2i, player_pos: Vector2i) -> Vector2i:
    var neighbors = [
        target + Vector2i(0, -1),  # above
        target + Vector2i(0, 1),   # below
        target + Vector2i(-1, 0),  # left
        target + Vector2i(1, 0),   # right
    ]
    # Return neighbor that is EMPTY and closest to player
    var best = Vector2i(-1, -1)
    var best_dist = INF
    for n in neighbors:
        if tile_manager.get_cell_type(n) == CellType.EMPTY:
            var dist = player_pos.distance_to(n)
            if dist < best_dist:
                best_dist = dist
                best = n
    return best
```

---

## Player Movement (Player.gd)

### Move and Mine
```gdscript
func move_to(target: Vector2i):
    var path = pathfinder.get_path(grid_position, target)
    if path.is_empty():
        return
    is_moving = true
    follow_path(path)

func move_then_mine(move_target: Vector2i, mine_target: Vector2i):
    var path = pathfinder.get_path(grid_position, move_target)
    if path.is_empty():
        return
    is_moving = true
    follow_path(path, func(): start_mining(mine_target))

func start_mining(target: Vector2i):
    is_mining = true
    mine_target = target
    # Face toward target
    # Play mining animation
    mining_timer.start(1.0 / mine_speed)

func _on_mining_timer_timeout():
    var cell_type = tile_manager.get_cell_type(mine_target)
    var hp = tile_manager.get_cell_hp(mine_target)
    hp -= mine_power
    if hp <= 0:
        finish_mining(mine_target)
    else:
        tile_manager.set_cell_hp(mine_target, hp)
        # Play hit effect

func finish_mining(cell: Vector2i):
    is_mining = false
    var ore_id = tile_manager.get_cell_ore(cell)
    tile_manager.set_cell_type(cell, CellType.EMPTY)
    pathfinder.set_cell_walkable(cell, true)
    
    if ore_id != "":
        spawn_ore_pickup(cell, ore_id)
    
    # Show +value popup
    show_value_popup(cell, ore_id)
    # Play mine complete sound + particles
    spawn_mine_particles(cell)
    
    # Update current depth
    current_depth = max(current_depth, cell.y)
```

---

## Lantern System (LanternSystem.gd)

### Depletion Design
Lantern depletes from TWO sources combined:
1. **Time-based** (primary pressure): slow constant drain even when standing still
2. **Action-based** (decision cost): extra drain per mine action and per move step

This means:
- Standing still to think: allowed, but time is passing
- Mining efficiently: rewarded vs random digging
- "One more cell" always has a real cost

### Core Logic
```gdscript
var max_lantern: float = 100.0
var current_lantern: float = 100.0
var is_depleted: bool = false

# TIME-BASED: constant drain per second (base pressure)
var time_depletion_rate: float = 0.8    # % per second (upgradeable)

# ACTION-BASED: extra drain per action
var mine_depletion_cost: float = 1.5   # % per mine action
var move_depletion_cost: float = 0.1   # % per cell moved (nearly negligible)

func _process(delta):
    if is_depleted:
        return
    drain(time_depletion_rate * delta)

func on_mine_action():
    drain(mine_depletion_cost)

func on_move_step():
    drain(move_depletion_cost)

func drain(amount: float):
    current_lantern -= amount
    current_lantern = max(0.0, current_lantern)
    update_light_radius()
    if current_lantern <= 0:
        is_depleted = true
        trigger_forced_evacuation()

func update_light_radius():
    var pct = current_lantern / max_lantern
    var radius = lerp(30.0, 150.0, pct)
    player_light.texture_scale = radius / 100.0

func trigger_forced_evacuation():
    game.force_evacuate()
```

### Depletion Feel Targets
```
Full lantern (100%): lasts ~3-4 minutes of active mining
Efficient play:      reach depth 40+ before 30% remaining
Inefficient play:    burns out before depth 20
Standing still:      burns ~15% per minute, enough to pressure movement
```

### Era Variations
```gdscript
enum LanternEra {
    CANDLE,
    # time_rate=1.2 (fast), mine_cost=2.0
    # Special: instantly extinguished by water cells
    # Special: wind tunnel cells accelerate drain 3x

    GAS_LAMP,
    # time_rate=0.8 (medium), mine_cost=1.5
    # Special: gas pocket cells trigger explosion risk
    # Special: can ignite flammable ore veins

    ELECTRIC,
    # time_rate=0.5 (slow), mine_cost=1.0
    # Special: requires charge stations in map
    # Special: magnetic ore cells cause short circuit spike
}
```

### Build System Integration
```gdscript
# 腐化矿灯 (Corrupted Lantern) - Darkness Build
# time_rate *= 2.0, mine_cost *= 2.0
# BUT: ores mined in darkness worth 2x value

# 静思头盔 (Meditation Helm) - Info Build
# time_rate = 0 when standing still
# Pairs with: 地质预言书 to plan full route before moving

# 冲锋镐 (Dash Pick) - Speed Build
# move_depletion_cost = 0 (free movement)
# mine_cost *= 1.5

# 节流阀 (Throttle Valve) - Survival Build
# time_rate *= 0.5, mine_cost *= 0.5
# BUT: mine_speed *= 0.7
```

---

## Backpack System (Backpack.gd)

### Core Logic
```gdscript
var max_weight: float = 10.0    # Upgradeable
var current_weight: float = 0.0
var contents: Dictionary = {}   # ore_id -> count

func try_add_ore(ore_id: String, count: int = 1) -> bool:
    var ore_data = OreDatabase.get(ore_id)
    var added_weight = ore_data.weight * count
    
    if current_weight + added_weight > max_weight:
        show_backpack_full_warning()
        return false
    
    current_weight += added_weight
    contents[ore_id] = contents.get(ore_id, 0) + count
    update_backpack_ui()
    return true

func get_total_value() -> int:
    var total = 0
    for ore_id in contents:
        var ore_data = OreDatabase.get(ore_id)
        total += ore_data.base_value * contents[ore_id]
    return total
```

---

## Session Results (ResultsScreen.gd)

### Results Data
```gdscript
func show_results(session_data: Dictionary):
    # session_data contains:
    # - ores_collected: Dictionary (ore_id -> count)
    # - gold_earned: int
    # - depth_reached: int
    # - lantern_remaining: float
    # - time_elapsed: float
    # - blueprints_found: Array
    
    # Display each ore type with icon + count + value
    # Show total gold earned
    # Show depth reached
    # Show rating (S/A/B/C based on depth + efficiency)
    # Two buttons: "Return to Camp" and "Mine Again"
    
    # Save gold to persistent storage
    SaveManager.add_gold(session_data.gold_earned)
```

---

## Camp Upgrades (Camp.gd)

### MVP Upgrade List
```gdscript
var upgrades = {
    "backpack_size": {
        "name": "背包扩容",
        "max_level": 5,
        "cost_per_level": [200, 350, 500, 800, 1200],
        "effect": func(level): Backpack.max_weight += 2.0
    },
    "lantern_duration": {
        "name": "灯具改良", 
        "max_level": 5,
        "cost_per_level": [150, 280, 420, 650, 1000],
        "effect": func(level): LanternSystem.depletion_rate *= 0.85
    },
    "mine_speed": {
        "name": "镐头强化",
        "max_level": 5, 
        "cost_per_level": [300, 480, 700, 1000, 1500],
        "effect": func(level): Player.mine_speed += 0.15
    },
    "mine_power": {
        "name": "破岩强化",
        "max_level": 3,
        "cost_per_level": [500, 900, 1500],
        "effect": func(level): Player.mine_power += 1
    }
}
```

---

## Visual Feedback (Critical - Polish This First)

### Mining Hit Effect
```
1. Small rock particle burst (5-8 particles, gray)
2. Screen shake: very subtle (0.5px, 0.1s)
3. Sound: dull thud
```

### Ore Discovered Effect
```
1. Larger particle burst (10-15 particles, ore's glow_color)
2. Gold number popup: "+{value}" floats up and fades (0.8s)
3. Font: bold, slightly larger than HUD text
4. Sound: bright chime, pitch varies by ore rarity
5. Light flash: brief pulse of ore's glow_color
```

### Backpack Full Warning
```
1. Backpack UI pulses red
2. Brief sound: low warning tone
3. No number popup for that ore
```

### Lantern Low Warning (< 20%)
```
1. Lantern bar pulses red
2. Light radius visibly flickers
3. Sound: crackling/sputtering
4. Screen vignette darkens slightly
```

---

## Equipment Slot System (for future sessions)

### Pre-session Setup Screen
```gdscript
var equipment_slots: int = 3    # Upgradeable
var equipped_items: Array = []  # Max length = equipment_slots

# Each item has:
# - item_id: String
# - weight_cost: float  (reduces effective backpack capacity)
# - effect: Callable    (applied at session start)

# Items the player can bring:
# - Dynamite: costs 2 weight, destroys 3x3 area
# - Rope: costs 1 weight, creates fast-travel shortcut
# - Lantern Oil: costs 1.5 weight, +30% lantern duration
# - Reinforced Bag: costs 2 weight, +4 max weight (net gain +2)
```

---

## Build / Combo System (post-MVP)

### Trigger Framework
Each tool can emit signals that other tools listen to:
```gdscript
signal on_mine_complete(cell: Vector2i, ore_id: String)
signal on_move_step(from: Vector2i, to: Vector2i)
signal on_backpack_fill_pct(pct: float)
signal on_lantern_pct(pct: float)
signal on_depth_change(new_depth: int)
```

### Example: Greedy Soul (贪婪之魂) - Overload Build
```gdscript
# Listens to backpack fill signal
func _on_backpack_fill_pct(pct):
    if pct > 0.9:
        player.mine_speed += 0.5   # Bonus speed when nearly full
        player.move_speed += 0.3
```

### Example: Corrupted Lantern (腐化矿灯) - Darkness Build
```gdscript
# Accelerates lantern depletion
func apply():
    LanternSystem.depletion_rate *= 2.0
    
# But ores mined in darkness are worth more
func _on_mine_complete(cell, ore_id):
    var in_darkness = LanternSystem.is_cell_in_darkness(cell)
    if in_darkness:
        var bonus = 2.0
        session_gold += OreDatabase.get(ore_id).base_value * bonus
```

---

## Key Zones (post-MVP)

### Zone Definitions
```gdscript
var zones = {
    "coal_mine": {
        "depth_start": 0,
        "depth_end": 50,
        "color_tint": Color(0.3, 0.3, 0.35),
        "ambient_light": Color(0.9, 0.7, 0.4),   # Warm candle yellow
        "era_required": "candle",
        "hazards": []
    },
    "volcanic": {
        "depth_start": 100,
        "depth_end": 180,
        "color_tint": Color(0.4, 0.15, 0.1),
        "ambient_light": Color(1.0, 0.4, 0.1),   # Deep red-orange
        "era_required": "electric",
        "hazards": ["lava_cell", "gas_pocket"]
    },
    "crystal_cave": {
        "depth_start": 70,
        "depth_end": 120,
        "color_tint": Color(0.1, 0.2, 0.4),
        "ambient_light": Color(0.3, 0.6, 0.9),   # Cold blue
        "era_required": "gas_lamp",
        "hazards": ["underground_river"]
    },
    "ancient_tomb": {
        "depth_start": 140,
        "depth_end": 200,
        "color_tint": Color(0.25, 0.2, 0.1),
        "ambient_light": Color(0.7, 0.55, 0.2),  # Dark gold
        "era_required": "gas_lamp",
        "hazards": ["trap_cell"],
        "blueprint_density": 3.0  # 3x more blueprint fragments
    }
}
```

---

## Save System (SaveManager.gd)

```gdscript
const SAVE_PATH = "user://save.json"

var data = {
    "total_gold": 0,
    "upgrades": {},          # upgrade_id -> level
    "blueprints": [],        # blueprint ids found
    "sessions_played": 0,
    "deepest_depth": 0,
    "total_gold_earned": 0,
    "era": "candle"          # current tech era
}

func save():
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(data))

func load():
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    data = JSON.parse_string(file.get_as_text())
```

---

## Development Order

### Phase 1 - Core Loop (Weeks 1-4)
1. TileMap setup with basic rock/empty/ore cells
2. Map generator (random rocks + ore placement)
3. AStarGrid2D pathfinding
4. Player click-to-move
5. Mining action (click rock → walk adjacent → mine → cell becomes empty)
6. Ore auto-collect on contact
7. Backpack weight system
8. Lantern depletion over time
9. Evacuation (walk to entrance → session ends)
10. Basic results screen (gold earned, depth)
11. Save/load gold
12. Camp screen with 2-3 upgrades

### Phase 2 - Feel Good (Weeks 5-6)
1. Particle effects for mining
2. +value number popups
3. Sound effects (mine hit, ore found, lantern warning)
4. Lantern light using Godot PointLight2D
5. Darkness vignette
6. Smooth player movement animation

### Phase 3 - Content (Weeks 7-12)
1. 4 ore types with different values/weights
2. Hard rock cells (multi-hit)
3. Blocked cells (visual only for now)
4. 2 zones with different color tints
5. Equipment slot system (pre-session loadout)
6. 3-4 equipment items
7. Blueprint fragment system

### Phase 4 - Build System (Months 4-6)
1. Trigger/signal framework for item combos
2. 6-8 tools with unique rule-changing effects
3. First 2-3 build archetypes working end-to-end
4. Camp expanded with full upgrade tree

---

## Important Design Rules (Do Not Break)

1. **No combat system** - no enemies, no HP for player from damage
2. **No gravity** - player moves freely through any empty cell
3. **Click-to-move only** - no WASD
4. **Auto-collect on contact** - no manual pickup button
5. **Ore disappears into backpack immediately** - no items lying on ground
6. **Tools change rules, not just numbers** - a tool that gives +10% mine speed is boring; a tool that mirrors your mining direction is interesting
7. **Every session end must feel like a choice** - player should sometimes regret evacuating too early, sometimes regret staying too long
8. **Lantern = session timer** - it is the only hard constraint on session length

---

## Art Direction Reference
Style: Modern 2D hand-drawn, NOT pixel art
Reference: Hades color saturation + Darkest Dungeon atmosphere
Key visual: Warm lantern glow in dark cave, ore self-illumination
UI: Dark semi-transparent panels, gold accent color (#B8860B)
Zone transitions: 3-5 second color tint lerp when entering new zone

Do not implement art in MVP. Use:
- Colored rectangles for tiles (gray=rock, brown=hard rock, yellow=gold ore, blue=crystal)
- Circle for player
- Simple bar for lantern/backpack UI
