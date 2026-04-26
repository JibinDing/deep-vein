# Deep Vein

Godot 4 MVP skeleton for a roguelike mining game.

## Current Flow

1. Open the folder in Godot 4.
2. Run the project. The main scene is `res://scenes/Camp.tscn`.
3. Click `下矿` to start a mining session.
4. Left-click empty cells to move.
5. Left-click rock or ore cells to walk adjacent and mine.
6. Press `E` or click the entrance to evacuate.

## Implemented Skeleton

- Camp screen with basic upgrades.
- Procedural grid map with entrance, tunnels, rocks, hard rocks, blocked cells, and ore.
- Click-to-move using `AStarGrid2D`.
- Mining turns cells into empty walkable cells.
- Ore collection goes directly into the backpack.
- Lantern drains over time, movement, and mining.
- Evacuation leads to a results screen.
- Gold and upgrades save to `user://save.json`.

## Next Work

- Replace placeholder grid art with TileMap tiles.
- Add mining particles, number popups, and sound.
- Apply the dark hand-drawn UI direction from the reference images.
- Add pre-session equipment and build-combo systems after the MVP loop feels good.
