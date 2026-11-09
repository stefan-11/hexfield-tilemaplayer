class_name PlayerController
extends Node
## Steuerung des Spieler-Teams während seines Zugs:
## Linksklick auf eine eigene Einheit wählt sie aus und zeigt ihre erreichbaren Felder,
## Linksklick auf ein erreichbares Feld bewegt sie dorthin.
## Rechtsklick oder Klick auf ein anderes Feld hebt die Auswahl auf.

@export var turn_manager: TurnManager

var board: Board

var _active := false
var _selected: Character
## Hex-Koordinate -> Wegkosten der ausgewählten Einheit
var _reachable := {}


func _ready() -> void:
	turn_manager.turn_started.connect(_on_turn_started)


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
	elif _selected and _reachable.has(cell):
		board.move_unit(_selected, cell)
		_select(_selected)
	else:
		_deselect()


func _select(unit: Character) -> void:
	_selected = unit
	_reachable = board.get_reachable(unit)
	board.reach_layer.show_cells(_reachable.keys())


func _deselect() -> void:
	_selected = null
	_reachable = {}
	if board:
		board.reach_layer.show_cells([])
