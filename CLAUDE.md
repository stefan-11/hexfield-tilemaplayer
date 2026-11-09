# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Hex-field based board game in **Godot 4.7** (GDScript, Mobile renderer). Levels are painted in the editor with `TileMapLayer` nodes, so game logic must work off whatever cells are painted rather than a hard-coded grid. The user communicates in German; answer in German.

## Commands

No build system, linter, or tests. The editor binary is not on `PATH`:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -e   # open editor
/Applications/Godot.app/Contents/MacOS/Godot --path .      # run main scene (main.tscn)
```

Prefer creating/changing nodes via instructions for the editor rather than hand-editing `.tscn`/`.tres` while the editor is open (it overwrites them; `unique_id`s and `uid://` references must stay consistent).

## Hex grid conventions (critical)

Configured in `hex_tileset.tres`, shared by all layers:

- `tile_shape = Hexagon`, `tile_offset_axis = Vertical Offset` → **flat-top** hexes (`hex-white.png`, 128×110, source id 0, atlas coords `(0, 0)`).
- `tile_layout = Stairs Down` → map coordinates are **axial `(q, r)`** = `Vector2i(x, y)`. +q moves one column right and half a hex down; +r moves straight down. This matches Red Blob Games' flat-top axial system.
- Neighbors of `(q, r)`: `(q±1, r)`, `(q, r±1)`, `(q+1, r-1)`, `(q-1, r+1)`; distance = `(|dq| + |dr| + |dq+dr|) / 2`. `get_surrounding_cells()` already respects this layout.
- Changing `tile_layout` remaps all painted cells — don't change it.
- Terrain: custom data layer `move_cost` (int) = cost to **enter** a cell. `<= 0` means impassable, and new tiles default to 0, so every new tile needs a value. Read it only via `Board.get_move_cost(cell)` (unpainted cells → 0).

## Scene structure

- `level_base.tscn`: `Board (TileMapLayer, level.gd = class_name Board, hex_tileset.tres)` → `Reach (highlight_layer.gd)`, `Path (highlight_layer.gd)`, `Hover (hover_highlight.gd)`, `Units (Node2D)`. Contains no painted cells. Child order = draw order.
- `level_XX.tscn`: inherited scenes of `level_base.tscn`; they only add `tile_map_data` (the painted level), units, and per-level exports of `level.gd` (e.g. `start_cell`, axial coords the camera starts on). Shared structure/overlays belong in `level_base.tscn`, never in individual levels.
- `main.tscn` + `main.gd`: `Main (Node2D)` holds `Camera`, `TurnManager`, `PlayerController`, `EnemyController`, `HUD` (`ui/hud.tscn`). At runtime it instantiates the `level_scene` export, hands the `Board` to camera/turn manager/player controller, then calls `TurnManager.start()`.

Overlay pattern: extra visual layers (hover, selection, movement range, …) are `TileMapLayer` children of `Board`. They inherit its transform, draw on top, copy `board.tile_set` in `_ready`, and tint via `modulate`. `Board` itself only holds level data; overlays only mark cells that exist on `Board` (`get_cell_source_id(cell) != -1`).

## Characters (`characters/`)

- One scene for all units: `character.tscn` + `character.gd` (`class_name Character`, `@tool`). Player vs. enemy is the `team` export, not a subclass; control (input vs. AI) belongs in a separate turn/controller system.
- Stats and graphics live in `CharacterType` resources (`character_type.gd`: `max_hp`, `move_range`, `attack_range` = hex distance for attacks, …), one `.tres` per type in `characters/types/`. New unit types = new `.tres`, no new scene.
- Units are instanced per level under `Board/Units`. `cell` (axial) is the source of truth; position is derived from it. In the editor, dragging a unit snaps it to the nearest hex and updates `cell`.
- `level.gd` keeps the `cell → Character` lookup (`get_unit_at`, `move_unit`). Always move units through `move_unit`, not by setting `cell` directly, or the lookup goes stale.

## Turns (`turns/`, `ui/`)

- `TurnManager` only knows `round_number` and `active_team` and emits `round_started` / `turn_started`. A round = player turn + enemy turn; at round start every unit's `moves_left` is reset to `type.move_range`. It knows nothing about input or UI — controllers and HUD listen to its signals.
- Movement rules are enforced in `Board`, not in controllers: `get_reachable(unit)` is a Dijkstra over hex neighbors using `get_move_cost`, up to `moves_left` (other units and impassable cells block), and `move_unit(unit, path)` takes the concrete path (incl. start cell, e.g. from `find_path`), rejects it if steps aren't adjacent, blocked, impassable or cost more than `moves_left`, and subtracts the path cost. Multiple partial moves per turn are allowed.
- Logic vs. presentation: `move_unit` updates the lookup, `moves_left` and `cell` immediately, then calls `Character.walk(path)`, which tweens along the path (`step_duration` per hex) and emits `walk_finished`. `_snap_to_cell` is suppressed while `is_walking`. Callers that need to wait (controllers, later AI) `await unit.walk_finished`; `PlayerController` blocks input while walking.
- `Board.find_path(from, to)` uses `HexAStar` (`hex_astar.gd`, `AStar2D` subclass: point position = axial cell, `weight_scale` = `move_cost`, hex-distance heuristic). Range-independent; returns cells incl. start and goal, empty if unreachable. Units are disabled as points only for the duration of each call. The graph is built once in `Board._ready()` — if tiles are changed at runtime, call `_build_astar()` again.
- `PlayerController`: click own unit → select + show `Reach` overlay; hovering any cell shows the full `find_path` route on the `Path` overlay (also beyond range); click any cell → move along that path, as far as `moves_left` allows (stops at the last cell in `get_reachable`); right-click or a cell without path → deselect. Only active during the player turn.
- `EnemyController`: placeholder that ends its turn immediately (deferred); enemy AI goes here.

## Camera / input

`camera.gd` (on `Main/Camera`) moves only via the input actions `camera_left/right/up/down` (defined in `project.godot`, arrow keys) and clamps to the painted board's bounds. Mouse edge-scrolling does not move the camera directly: it emits `InputEventAction`s with a dedicated `device` id (`EDGE_DEVICE`). Don't switch this to `Input.action_press/action_release` — `action_release` also cancels a held arrow key for the same action. Edge-scrolling stays off until the first `InputEventMouseMotion`, because Godot reports the mouse at `(0, 0)` before that (would scroll to the top-left on startup).
