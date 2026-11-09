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
var _selected: Character
## Hex-Koordinate -> Wegkosten der ausgewählten Einheit
var _reachable := {}
## Feld, für das zuletzt ein Weg angezeigt wurde.
var _preview_target := NO_CELL


func _ready() -> void:
	turn_manager.turn_started.connect(_on_turn_started)


func _process(_delta: float) -> void:
	if _selected == null:
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
	if not _active or not event is InputEventMouseButton or not event.pressed:
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
		var stop := _last_reachable(path)
		if stop != _selected.cell:
			board.move_unit(_selected, stop)
			_select(_selected)
	else:
		_deselect()


## Letztes Feld auf `path`, das die ausgewählte Einheit mit ihrer Restreichweite erreicht.
## Da `path` ein günstigster Weg ist, steigen die Kosten entlang des Wegs nur an.
func _last_reachable(path: Array[Vector2i]) -> Vector2i:
	var stop := path[0]
	for cell in path.slice(1):
		if not _reachable.has(cell):
			break
		stop = cell
	return stop


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
