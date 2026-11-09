class_name TurnManager
extends Node
## Verwaltet Runden und welches Team gerade am Zug ist.
## Eine Runde besteht aus Spielerzug und Gegnerzug. Zu Beginn jeder Runde
## bekommen alle Einheiten ihre volle Reichweite zurück.

signal round_started(round_number: int)
signal turn_started(team: Character.Team)

var board: Board
var round_number := 0
var active_team := Character.Team.PLAYER


func start() -> void:
	_start_round()


func end_turn() -> void:
	if active_team == Character.Team.PLAYER:
		_start_turn(Character.Team.ENEMY)
	else:
		_start_round()


func _start_round() -> void:
	round_number += 1
	for unit in board.get_units():
		unit.reset_for_round()
	round_started.emit(round_number)
	_start_turn(Character.Team.PLAYER)


func _start_turn(team: Character.Team) -> void:
	active_team = team
	turn_started.emit(team)
