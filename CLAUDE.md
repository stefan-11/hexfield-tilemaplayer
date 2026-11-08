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

## Scene structure

- `level_base.tscn`: `Board (TileMapLayer, level.gd, hex_tileset.tres)` → `Hover (TileMapLayer, hover_highlight.gd)`, `Units (Node2D)`. Contains no painted cells.
- `level_XX.tscn`: inherited scenes of `level_base.tscn`; they only add `tile_map_data` (the painted level) and per-level exports of `level.gd` (e.g. `start_cell`, axial coords the camera starts on). Shared structure/overlays belong in `level_base.tscn`, never in individual levels.
- `main.tscn` + `main.gd`: `Main (Node2D)` instantiates the `PackedScene` set in its `level_scene` export at runtime and calls `Camera.fit_to_board(board)`.

## Characters (`characters/`)

- One scene for all units: `character.tscn` + `character.gd` (`class_name Character`, `@tool`). Player vs. enemy is the `team` export, not a subclass; control (input vs. AI) belongs in a separate turn/controller system.
- Stats and graphics live in `CharacterType` resources (`character_type.gd`), one `.tres` per type in `characters/types/`. New unit types = new `.tres`, no new scene.
- Units are instanced per level under `Board/Units`. `cell` (axial) is the source of truth; position is derived from it. In the editor, dragging a unit snaps it to the nearest hex and updates `cell`.
- `level.gd` keeps the `cell → Character` lookup (`get_unit_at`, `move_unit`). Always move units through `move_unit`, not by setting `cell` directly, or the lookup goes stale.

## Camera / input

`camera.gd` (on `Main/Camera`) moves only via the input actions `camera_left/right/up/down` (defined in `project.godot`, arrow keys) and clamps to the painted board's bounds. Mouse edge-scrolling does not move the camera directly: it emits `InputEventAction`s with a dedicated `device` id (`EDGE_DEVICE`). Don't switch this to `Input.action_press/action_release` — `action_release` also cancels a held arrow key for the same action. Edge-scrolling stays off until the first `InputEventMouseMotion`, because Godot reports the mouse at `(0, 0)` before that (would scroll to the top-left on startup).

Overlay pattern: extra visual layers (hover, selection, movement range, …) are `TileMapLayer` children of `Board`. They inherit its transform, draw on top, copy `board.tile_set` in `_ready`, and tint via `modulate`. `Board` itself only holds level data; overlays only mark cells that exist on `Board` (`get_cell_source_id(cell) != -1`).
