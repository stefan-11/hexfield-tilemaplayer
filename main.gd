extends Node2D
## Lädt das Level, das im Inspector unter "Level Scene" eingetragen ist,
## verbindet es mit Kamera und Rundensteuerung und startet die erste Runde.

@export var level_scene: PackedScene

@onready var camera: Camera2D = $Camera
@onready var turn_manager: TurnManager = $TurnManager
@onready var player_controller: PlayerController = $PlayerController


func _ready() -> void:
	var board: Board = level_scene.instantiate()
	add_child(board)
	camera.fit_to_board(board, board.start_cell)
	turn_manager.board = board
	player_controller.board = board
	turn_manager.start()
