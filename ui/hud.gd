extends CanvasLayer
## Zeigt Runde und aktives Team an und bietet den Button zum Beenden des Zugs.

@export var turn_manager: TurnManager

@onready var turn_label: Label = $Panel/VBox/TurnLabel
@onready var end_turn_button: Button = $Panel/VBox/EndTurnButton


func _ready() -> void:
	turn_manager.turn_started.connect(_on_turn_started)
	end_turn_button.pressed.connect(turn_manager.end_turn)


func _on_turn_started(team: Character.Team) -> void:
	var team_name := "Spieler" if team == Character.Team.PLAYER else "Gegner"
	turn_label.text = "Runde %d · %s" % [turn_manager.round_number, team_name]
	end_turn_button.disabled = team != Character.Team.PLAYER
