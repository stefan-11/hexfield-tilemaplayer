class_name EnemyController
extends Node
## Steuerung des Gegner-Teams. Beendet seinen Zug vorerst sofort;
## hier kommt später die KI hinein.

@export var turn_manager: TurnManager


func _ready() -> void:
	turn_manager.turn_started.connect(_on_turn_started)


func _on_turn_started(team: Character.Team) -> void:
	if team == Character.Team.ENEMY:
		# Deferred, damit der Zugwechsel nicht mitten in der Signal-Verarbeitung passiert.
		turn_manager.end_turn.call_deferred()
