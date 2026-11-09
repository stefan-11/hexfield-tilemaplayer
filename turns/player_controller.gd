class_name PlayerController
extends Node
## Steuerung des Spieler-Teams während seines Zugs:
## Linksklick auf eine eigene Einheit wählt sie aus und zeigt ihre erreichbaren Felder,
## Linksklick auf ein Feld bewegt sie entlang des angezeigten Wegs dorthin, bei Zielen
## außerhalb der Reichweite so weit, wie die Restreichweite reicht.
## Steht die Maus über einem Feld, wird der Weg dorthin angezeigt (auch außerhalb der Reichweite).
## Rechtsklick oder Klick auf ein Feld ohne Weg hebt die Auswahl auf.

const NO_CELL := Vector2i(-99999, -99999)

@export var turn_manager: TurnManager

var board: Board

var _active := false
## true, solange eine Figur läuft; Eingaben und Wegvorschau ruhen dann.
var _busy := false
var _selected: Character
## Hex-Koordinate -> Wegkosten der ausgewählten Einheit
var _reachable := {}
## Feld, für das zuletzt ein Weg angezeigt wurde.
var _preview_target := NO_CELL


func _ready() -> void:
	turn_manager.turn_started.connect(_on_turn_started)


func _process(_delta: float) -> void:
	if _selected == null or _busy:
		return
	# Jeden Frame prüfen statt nur bei Mausbewegung, da auch die Kamera
	# das Feld unter der Maus verändert.
	var cell := board.local_to_map(board.get_local_mouse_position())
	if cell == _preview_target:
		return
	_preview_target = cell
	# Auch über die Reichweite hinaus, damit der Spieler die geplante Route sieht.
	var path := board.find_path(_selected.cell, cell)
	# Ohne Startfeld, dort steht die Figur selbst.
	board.path_layer.show_cells(path.slice(1))


func _on_turn_started(team: Character.Team) -> void:
	_active = team == Character.Team.PLAYER
	_deselect()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or _busy or not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_deselect()
	elif event.button_index == MOUSE_BUTTON_LEFT:
		_on_cell_clicked(board.local_to_map(board.get_local_mouse_position()))
	else:
		return
	get_viewport().set_input_as_handled()


func _on_cell_clicked(cell: Vector2i) -> void:
	var unit := board.get_unit_at(cell)
	if unit and unit.team == Character.Team.PLAYER:
		_select(unit)
	elif _selected:
		var path := board.find_path(_selected.cell, cell)
		if path.is_empty():
			_deselect()
			return
		var walk := _reachable_part(path)
		if walk.size() > 1:
			_move_selected(walk)
	else:
		_deselect()


## Anfang von `path` bis zum letzten Feld, das die ausgewählte Einheit mit ihrer
## Restreichweite erreicht. Da `path` ein günstigster Weg ist, steigen die Kosten nur an.
func _reachable_part(path: Array[Vector2i]) -> Array[Vector2i]:
	var end := 1
	while end < path.size() and _reachable.has(path[end]):
		end += 1
	return path.slice(0, end)


func _move_selected(path: Array[Vector2i]) -> void:
	var unit := _selected
	if not board.move_unit(unit, path):
		return
	_busy = true
	board.reach_layer.show_cells([])
	board.path_layer.show_cells([])
	await unit.walk_finished
	_busy = false
	# Auswahl kann inzwischen aufgehoben sein, z. B. durch Zugende.
	if _selected == unit:
		_select(unit)


func _select(unit: Character) -> void:
	_selected = unit
	_reachable = board.get_reachable(unit)
	board.reach_layer.show_cells(_reachable.keys())
	_preview_target = NO_CELL


func _deselect() -> void:
	_selected = null
	_reachable = {}
	_preview_target = NO_CELL
	if board:
		board.reach_layer.show_cells([])
		board.path_layer.show_cells([])
